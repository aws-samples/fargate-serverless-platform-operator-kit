################################################################################
# ECS Cluster Fargate Configuration
################################################################################

variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

################################################################################
# AquaSec Integration
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

variable "aquasec_registry" {
  description = "Parameter for AquaSec Integration Registry"
  type        = map(string)
  default = {
    name            = "ECR Integration"
    type            = "AWS"
    author          = "example@amazon.com"
    arn_role        = "arn:aws:iam::809940063064:role/Admin"
    sts_external_id = "IsengardExternalIduNsxNCILFN16"
    image_pull      = "sonarqube"
    tag_included    = "9.9.4-community"
    tag_excluded    = "xyz"
    ecr_repository  = "809940063064.dkr.ecr.us-east-1.amazonaws.com"
  }
}

variable "username" {
  description = "Aquasec Username"
  type        = string
}

variable "aqua_url" {
  description = "Aquasec Username"
  type        = string
}

variable "password" {
  description = "Aquasec Username"
  type        = string
}