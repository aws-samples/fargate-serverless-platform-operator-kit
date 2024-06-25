# Configure the AquaSec provider
provider "aquasec" {
  username = var.username
  aqua_url = var.aqua_url
  password = var.password

  # If you are using unverifiable certificates (e.g. self-signed) you may need to disable certificate verification
  verify_tls = false # Alternatively sourced from $AQUA_TLS_VERIFY
}

################################################################################
# Supply Chain
################################################################################

resource "aquasec_integration_registry" "integration_registry" {
  count                     = var.enable_aquasec ? 1 : 0
  name                      = var.aquasec_registry.name
  type                      = var.aquasec_registry.type
  advanced_settings_cleanup = false
  always_pull_patterns      = [":latest", ":${var.aquasec_registry.tag_included}"]
  author                    = var.aquasec_registry.author
  auto_cleanup              = false
  auto_pull                 = true
  auto_pull_interval        = 1
  auto_pull_max             = 100
  auto_pull_rescan          = false
  auto_pull_time            = "08:45"
  description               = "Automatically discovered registry"

  options {
    option = "ARNRole"
    value  = var.aquasec_registry.arn_role
  }
  options {
    option = "sts:ExternalId"
    value  = var.aquasec_registry.sts_external_id
  }
  options {
    option = "TestImagePull"
    value  = "${var.aquasec_registry.image_pull}:${var.aquasec_registry.tag_included}"
  }

  prefixes = [
    var.aquasec_registry.ecr_repository
  ]

  pull_image_age              = "0D"
  pull_image_count            = 3
  pull_image_tag_pattern      = [":${var.aquasec_registry.tag_included}"]
  pull_repo_patterns_excluded = [":${var.aquasec_registry.tag_excluded}"]

  url          = var.account.region
  scanner_name = []
  scanner_type = "any"

}

################################################################################
# ECR Repository
################################################################################

module "ecr" {
  count = var.enable_aquasec_sidecar ? 1 : 0
  #checkov:skip=CKV_TF_1:Using full commit hash generate a bug where the ref is not found on the CI.
  source                                 = "terraform-aws-modules/ecr/aws"
  version                                = "1.6.0"
  repository_name                        = "aqua-sidecar"
  registry_scan_type                     = "BASIC"
  repository_image_tag_mutability        = "IMMUTABLE"
  manage_registry_scanning_configuration = true
  create_lifecycle_policy                = false
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter         = "*"
      filter_type    = "WILDCARD"
    }
  ]
}