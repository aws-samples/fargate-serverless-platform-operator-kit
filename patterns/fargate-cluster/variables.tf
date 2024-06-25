################################################################################
# ECS Cluster Fargate Configuration
################################################################################
variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  default     = "ecs-core"
}

variable "tags" {
  description = "Resources Tagging"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Spok"
  }
}

variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

variable "ecr_repository_name" {
  type        = string
  description = "The ECR repository name for the app"
}

################################################################################
# ECS Service Sample
################################################################################
variable "service_sample" {
  description = "Parameter for Service Sample"
  type        = map(string)
  default = {
    cpu    = 1024
    memory = 4096
    name   = "ecsdemo"
  }
}

variable "container_sample" {
  description = "Parameter for Container Sample"
  type        = map(string)
  default = {
    cpu    = 512
    memory = 1024
    port   = 3000
    name   = "ecs-sample"
    image  = "public.ecr.aws/aws-containers/ecsdemo-nodejs:c3e96da"
  }
}

variable "container_sample_entrypoint" {
  description = "Container Sample Entrypoint"
  type        = list(any)
  default     = []
}

variable "container_sample_command" {
  description = "Container Sample Command"
  type        = list(any)
  default     = []
}

variable "container_sample_environment" {
  description = "Container Sample Environment Variables"
  type        = list(any)
  default     = []
}

variable "container_sample_volumes_from" {
  description = "Container Sample Volumes From Container"
  type = list(object({
    sourceContainer = string,
    readOnly        = bool
  }))
  default = []
}

################################################################################
# Networking
################################################################################

# Networking

variable "network" {
  description = "Parameter for Networking"
  type        = map(string)
  default = {
    vpc_cidr                      = "10.0.0.0/16"
    enable_nat_gateway            = true
    single_nat_gateway            = true
    enable_dns_hostnames          = true
    manage_default_network_acl    = true
    manage_default_route_table    = true
    manage_default_security_group = true
  }
}

################################################################################
# Module - Aquasec
################################################################################

variable "enable_aquasec" {
  description = "Enable or Disable Aquasec Integration"
  type        = bool
  default     = false
}

variable "enable_aquasec_sidecar" {
  description = "Enable or Disable Aquasec Sidecar"
  type        = bool
  default     = false
}

variable "enable_aquasec_sidecar_ecr_repository" {
  description = "Enable or Disable Aquasec Sidecar ECR Registry"
  type        = bool
  default     = false
}

variable "aquasec" {
  description = "Parameter for AquaSec"
  type        = map(string)
  default = {
    secret_manager_name = "aquasec"
  }
}

variable "aquasec_registry" {
  description = "Parameter for AquaSec Integration Registry"
  type        = map(string)
  default = {
    name            = "ECR Integration"
    type            = "AWS"
    author          = "example@amazon.com"
    arn_role        = "arn:aws:iam::xxxxxxxx:role/AquaSec"
    sts_external_id = "AquaSecExternalIDxxxxxxxx"
    image_pull      = "xyz"
    tag_included    = "xyz"
    tag_excluded    = "xyz"
    ecr_repository  = "xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com"
  }
}

variable "aquasec_microenforcer_sidecar" {
  description = "Parameter for AquaSec MicroEnforcer Sidecar"
  type        = map(string)
  default = {
    name               = "aqua-sidecar"
    cpu                = 512
    memory             = 1024
    essential          = false
    image              = "xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest"
    memory_reservation = 50
  }
}

################################################################################
# Module - Datadog
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

################################################################################
# Module - Codepipeline with Github
################################################################################

variable "enable_codepipeline_github" {
  description = "Enable or Disable Codepipeline and Github Integration"
  type        = bool
  default     = false
}

variable "secret_manager_name" {
  type        = string
  description = "Github Secret Manager Name"
}

variable "repository_name" {
  type        = string
  description = "The repository name to use in CodePipeline source stage"
}

variable "dockerhub_secret_name" {
  type        = string
  description = "AWS Secrets Manager secret name for dockerhub credentials"
}

################################################################################
# Load Balancer Configurations
################################################################################

variable "load_balancer" {
  description = "Parameters for Load Balancer"
  type        = map(string)
  default = {
    enable_deletion_protection = true
  }
}
