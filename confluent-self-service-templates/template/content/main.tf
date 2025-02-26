terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 0.2.0"  # Adjust this version constraint as needed.
    }
  }
}
provider "confluent" {
  # Use your Confluent Cloud credentials (set these via environment variables)
  # For example, export CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET
}

variable "environment_name" {
  type    = string
  default = "${{ values.environment_name }}"
}


resource "confluent_environment" "this" {
  display_name = var.environment_name
}

