# [Backstage](https://backstage.io)


# Building a Self-Service Developer Platform with Backstage and Confluent Cloud

## Introduction

In this blog post, I'll walk you through the process of building a self-service developer platform using Spotify's Backstage as the foundation and Confluent Cloud as a key service offering. This guide documents the journey from a basic Backstage installation to a full-featured platform that enables developers to provision their own Confluent Cloud environments via a streamlined, GitOps-driven workflow.

## What We'll Cover

1. Setting up Backstage with GitHub authentication
2. Configuring the organizational structure
3. Creating a software catalog
4. Building a custom template for Confluent Cloud provisioning
5. Implementing Infrastructure as Code with Terraform
6. Automating deployment with GitHub Actions

## Prerequisites

- Basic understanding of Backstage
- Familiarity with Terraform and Confluent Cloud
- A GitHub account and basic Git knowledge
- Node.js and Yarn installed

## Step 1: Setting Up Backstage with GitHub Authentication

We started with a basic Backstage installation and configured GitHub authentication to provide a secure, identity-based access system.

The key parts of our authentication setup in `app-config.yaml`:

```yaml
auth:
  environment: development
  providers:
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        signIn:
          resolvers:
            - resolver: usernameMatchingUserEntityName
```

And in our backend:

```typescript
// auth plugin
backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-auth-backend-module-github-provider'));
```

In the frontend App.tsx, we added:

```typescript
components: {
  SignInPage: props => (
    <SignInPage
      {...props}
      auto
      provider={{
        id: 'github-auth-provider',
        title: 'GitHub',
        message: 'Sign in using GitHub',
        apiRef: githubAuthApiRef,
      }}
    />
  ),
}
```

## Step 2: Configuring the Organizational Structure

We defined our organization's structure in `confluent-self-service-templates/org.yaml`:

```yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: dwessendorf
  annotations:
    github.com/login: dwessendorf
spec:
  profile:
    displayName: "Daniel Wessendorf"
    email: "dan@bossmail.de"
  memberOf: [guests]

---
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: guests
spec:
  type: team
  children: []
```

This establishes a simple organizational model with a "guests" group and a user belonging to that group.

## Step 3: Creating Our Software Catalog

The software catalog is the heart of Backstage, providing an inventory of all our software components. We set up a basic catalog in `examples/entities.yaml`:

```yaml
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: examples
spec:
  owner: guests

---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: example-website
spec:
  type: website
  lifecycle: experimental
  owner: guests
  system: examples
  providesApis: [example-grpc-api]

---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: example-grpc-api
spec:
  type: grpc
  lifecycle: experimental
  owner: guests
  system: examples
  definition: |
    syntax = "proto3";

    service Exampler {
      rpc Example (ExampleMessage) returns (ExampleMessage) {};
    }

    message ExampleMessage {
      string example = 1;
    };
```

This establishes:
- A system called "examples"
- A website component that belongs to that system
- A gRPC API provided by the website

## Step 4: Building a Confluent Cloud Template

Next, we created a custom template for provisioning Confluent Cloud environments. This template, defined in `confluent-self-service-templates/template/template.yaml`, lets developers create new Confluent Cloud environments through a simple form interface.

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: confluent-cloud-environment  
  title: Deploy Confluent Cloud Environment
  description: A Backstage template to create a Confluent Cloud environment using Terraform.
spec:
  owner: group:guests
  type: service

  parameters:
    - title: Confluent Cloud Configuration
      required:
        - environment_name
        - confluent_api_key
        - confluent_api_secret
      properties:
        environment_name:
          title: Environment Name
          type: string
          description: Name of the Confluent Cloud environment.
        confluent_api_key:
          title: Confluent API Key
          type: string
          description: API Key for Confluent Cloud authentication.
        confluent_api_secret:
          title: Confluent API Secret
          type: string
          description: API Secret for Confluent Cloud authentication.
```

The template implements a multi-step process:
1. Fetch a template with Terraform code
2. Publish to GitHub
3. Register the new component in Backstage

## Step 5: Implementing Infrastructure as Code with Terraform

The heart of our solution is a Terraform configuration that provisions Confluent Cloud resources. The main.tf file:

```hcl
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 0.2.0"
    }
  }
}

provider "confluent" {
  # Credentials are passed via environment variables
}

variable "environment_name" {
  type    = string
  default = "${{ values.environment_name }}"
}

resource "confluent_environment" "this" {
  display_name = var.environment_name
}

output "environment_id" {
  value = confluent_environment.this.id
}

output "environment_name" {
  value = confluent_environment.this.display_name
}
```

This Terraform code creates a new Confluent Cloud environment with the name specified by the user in the template form.

## Step 6: Automating Deployment with GitHub Actions

To automate the deployment of our Confluent Cloud environments, we use GitHub Actions. The workflow file `.github/workflows/terraform-deploy.yml`:

```yaml
name: "Terraform Deploy"

on:
  workflow_dispatch:
  push:

permissions:
  contents: write

jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      CONFLUENT_CLOUD_API_KEY: ${{ secrets.CONFLUENT_CLOUD_API_KEY }}
      CONFLUENT_CLOUD_API_SECRET: ${{ secrets.CONFLUENT_CLOUD_API_SECRET }}

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.0.0

      - name: Initialize Terraform
        working-directory: .
        run: terraform init

      - name: Validate Terraform
        working-directory: .
        run: terraform validate

      - name: Plan Terraform
        working-directory: .
        run: terraform plan -out=tfplan

      - name: Apply Terraform
        working-directory: .
        run: terraform apply -auto-approve tfplan
```

This workflow runs Terraform to create the Confluent Cloud environment whenever code is pushed to the repository or when manually triggered.

## Step 7: Documentation Generation

As a final touch, our GitHub Action also generates documentation based on the Terraform outputs:

```yaml
- name: Extract Terraform Outputs and Create Documentation
  run: |
    # Properly capture terraform outputs
    ENV_ID=$(${TERRAFORM_BIN} output -raw environment_id)
    ENV_NAME=$(${TERRAFORM_BIN} output -raw environment_name)
    
    # Create documentation files
    mkdir -p docs
    
    cat > docs/environment-details.md << EOL
    # Environment Details
    
    ## Environment Information
    
    - **Name**: ${ENV_NAME}
    - **Environment ID**: ${ENV_ID}
    EOL
```

This creates useful documentation that helps developers understand the resources that have been created and how to access them.

## The User Journey

Let's walk through the user journey:

1. A developer logs into Backstage using their GitHub credentials
2. They navigate to the "Create" page and select the "Deploy Confluent Cloud Environment" template
3. They fill in the form with their desired environment name and Confluent Cloud credentials
4. The system creates a new GitHub repository with Terraform code
5. GitHub Actions runs the Terraform code to provision the Confluent Cloud environment
6. The new environment is registered in the Backstage catalog
7. Documentation is automatically generated with access details

## Conclusion

We've built a powerful self-service platform that enables developers to provision their own Confluent Cloud environments with just a few clicks. This approach:

- Reduces the operational burden on platform teams
- Ensures consistency through Infrastructure as Code
- Provides a great developer experience
- Maintains visibility and governance through the Backstage catalog

By combining Backstage, GitHub, Terraform, and Confluent Cloud, we've created a solution that demonstrates the power of modern developer platforms.

## Next Steps

Future enhancements could include:
- Adding more resource types (Kafka clusters, topics, etc.)
- Implementing approvals for certain operations
- Cost tracking and quota management
- Integration with monitoring systems

The complete code for this project is available in the associated GitHub repository.

Happy coding!
