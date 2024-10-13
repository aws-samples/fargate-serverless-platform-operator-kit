################################################################################
# ECS Cluster Fargate Configuration
################################################################################
variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  default     = "ecs-core"
}

variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

variable "account_id" {
  description = "Accound ID"
  type        = string
}


################################################################################
# Github Integration
################################################################################

variable "secret_manager_name" {
  type        = string
  description = "Github Secret Manager Name"
}

variable "ecr_repository_name" {
  type        = string
  description = "The ECR repository name for the app"
}

variable "repository_name" {
  type        = string
  description = "The repository name to use in CodePipeline source stage"
}

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
  }
}

variable "secret_github" {
  default = {
    code_star_connection_arn = "code_star_connection_arn"
    organization_name = "organization_name"
  }

  type = map(string)
}