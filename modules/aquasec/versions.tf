terraform {
  required_version = ">= 1.0"

  required_providers {
    aquasec = {
      version = "0.8.27"
      source  = "aquasecurity/aquasec"
    }
  }
}