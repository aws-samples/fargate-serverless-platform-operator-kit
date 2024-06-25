data "aws_secretsmanager_secret" "github" {
  name = var.secret_manager_name
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.github.id
}

################################################################################
# CodePipeline Artifacts Bucket
################################################################################

module "pipeline_artifacts_bucket" {
  source       = "./s3"
  bucket_name  = "${var.account_id}-ecs-github-pipeline-artifacts"
  kms_key_name = "${var.account_id}-ecs-github-pipeline-artifacts-key"
}

################################################################################
# Microservice pipeline
################################################################################

module "python_microservice_pipeline" {
  source                              = "./codepipeline_python"
  repository_name                     = var.repository_name
  artifacts_bucket_arn                = module.pipeline_artifacts_bucket.bucket_arn
  artifacts_bucket_encryption_key_arn = module.pipeline_artifacts_bucket.bucket_key_arn
  account_id                          = var.account_id
  aws_region                          = var.account.region
  pipeline_articats_bucket_name       = module.pipeline_artifacts_bucket.bucket_name
  ecr_repository_name                 = var.ecr_repository_name
  cluster_name                        = var.cluster_name
  container_name                      = var.container_sample.name
  service_name                        = var.service_sample.name
  organization_name                   = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["organization_name"]
  code_star_connection_arn            = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["code_star_connection_arn"]
  dockerhub_secret_name               = var.dockerhub_secret_name
}

################################################################################
# ECR Repository
################################################################################

module "ecr" {
  #checkov:skip=CKV_TF_1:Using full commit hash generate a bug where the ref is not found on the CI.
  source                                 = "terraform-aws-modules/ecr/aws"
  version                                = "1.6.0"
  repository_name                        = var.ecr_repository_name
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