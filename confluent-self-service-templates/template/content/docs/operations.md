# Operations Guide

## Accessing the Environment

To access this environment in the Confluent Cloud Console:

1. Log in to [Confluent Cloud](https://confluent.cloud/)
2. Navigate to Environments
3. Select "${{ values.environment_name }}" from the list

## Using the CLI

You can use the Confluent CLI to interact with this environment:

```bash
# Set up authentication
confluent login

# List available environments
confluent environment list

# Select this environment
confluent environment use <ENVIRONMENT_ID>