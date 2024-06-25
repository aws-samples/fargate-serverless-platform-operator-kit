################################################################################
# ECS Cluster Fargate Configuration
################################################################################
variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  default     = "ecs-core"
}

################################################################################
# Datadog Integration
################################################################################

variable "enable_datadog" {
  description = "Enable or Disable Datadog Integration"
  type        = bool
  default     = false
}

variable "sns_topic_name_for_alerts" {
  description = "SNS Topic for alerts"
  type        = string
  nullable    = false

}

variable "datadog_integration_aws" {
  description = "Datadog integration variables"
  type        = map(string)
  default = {
    roleName           = "DatadogAWSIntegrationRole"
    cpuutilization     = "80"
    memory_utilization = "80"
  }
}

variable "api_key" {
  description = "Datadog API Key"
  type        = string
}

variable "app_key" {
  description = "Datadog APP Key"
  type        = string
}