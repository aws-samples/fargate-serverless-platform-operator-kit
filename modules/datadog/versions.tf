terraform {
  required_version = ">= 1.0"

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 3.36.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.22"
    }
  }
}