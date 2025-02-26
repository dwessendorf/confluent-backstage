# Environment Details

## Environment Information

- **Name**: ${{ values.environment_name }}
- **Cloud Provider**: {% raw %}{{ env_output.cloud_provider }}{% endraw %}
- **Region**: {% raw %}{{ env_output.region }}{% endraw %}
- **Environment ID**: {% raw %}{{ env_output.environment_id }}{% endraw %}

The Environment ID will be automatically populated after the Terraform deployment completes successfully.

## Access

Access to this environment is controlled via Confluent Cloud. Please contact the administrators to request access.