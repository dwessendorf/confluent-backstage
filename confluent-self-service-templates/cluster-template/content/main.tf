terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 0.2.0"
    }
  }
}

provider "confluent" {
  # The provider will automatically use CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET
  # environment variables without explicit configuration
}

variable "cluster_name" {
  type    = string
  default = "${{ values.cluster_name }}"
}

variable "environment_name" {
  type    = string
  default = "${{ values.environment_name }}"
}

variable "cloud_provider" {
  type    = string
  default = "${{ values.cloud_provider }}"
}

variable "region" {
  type    = string
  default = "${{ values.region }}"
}

variable "availability" {
  type    = string
  default = "${{ values.availability }}"
}


# Get the environment ID from the environment name
data "confluent_environment" "this" {
  display_name = var.environment_name
}

resource "confluent_kafka_cluster" "this" {
  display_name = var.cluster_name
  availability = var.availability
  cloud        = var.cloud_provider
  region       = var.region
  basic  {}

  environment {
    id = data.confluent_environment.this.id
  }
}

# Add outputs to be used in documentation
output "cluster_id" {
  value = confluent_kafka_cluster.this.id
  description = "The ID of the created Confluent Cloud cluster"
}

output "cluster_name" {
  value = confluent_kafka_cluster.this.display_name
  description = "The name of the created Confluent Cloud cluster"
}

output "bootstrap_endpoint" {
  value = confluent_kafka_cluster.this.bootstrap_endpoint
  description = "The bootstrap endpoint for the cluster"
  sensitive = true
}

output "environment_id" {
  value = data.confluent_environment.this.id
  description = "The ID of the parent environment"
}

output "environment_name" {
  value = data.confluent_environment.this.display_name
  description = "The name of the parent environment"
} 