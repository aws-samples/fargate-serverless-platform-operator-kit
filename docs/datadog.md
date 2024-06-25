## Monitoring Component - Datadog integration module

The sensitive information for Datadog will be managed by AWS Secrets Manager, please create the following secret for the keys:

```shell
aws secretsmanager create-secret \
    --name datadog \
    --description "Datadog Secrets" \
    --secret-string "{\"datadog_api_key\":\"abc123.......\",\"datadog_app_key\":\"abc123........\"}"
```
- **datadog_api_key**: Should be the API Key created by your org on Datadog.
- **datadot_app_key**: Should be the Application Key created by your org on Datadog.

For more information about the Keys used by Datadog please check the [official docs](https://docs.datadoghq.com/account_management/api-app-keys/).

Configure the following parameters on **patterns/fargate-cluster/terraform.tfvars**:

```shell
################################################################################
# Module - Datadog
################################################################################

enable_datadog = true

sns_topic_name_for_alerts = "sns-containters-ecs-topic-alerts"

# Secret Manager Value Example
# {"datadog_api_key":"XXXXXX","datadog_app_key":"XXXXX"}

datadog_integration_aws = {
  roleName                           = "DatadogAWSIntegrationRole"
  alert_cpuutilization_threshold     = "80"
  alert_memory_utilization_threshold = "80"
  secret_manager_name                = "datadog"
  external_id                        = "XXXXXX"
}
```

Deploy datadog Integration:

```shell
terraform init
terraform validate
terraform plan #Here check the plan that Terraform outputs in case you want to change something.
terraform apply --auto-approve
```