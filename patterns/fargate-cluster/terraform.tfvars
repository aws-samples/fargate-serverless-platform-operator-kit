################################################################################
# ECS Cluster Fargate Configuration
################################################################################

cluster_name = "ecs-core"

tags = {
  Environment = "Development"
  Project     = "Spok"
}

account = {
  region = "us-east-1"
}

ecr_repository_name = "ecs-core"

################################################################################
# ECS Service Sample
################################################################################

service_sample = {
  cpu    = 2048
  memory = 4096
  name   = "ecsdemo"
}

container_sample = {
  cpu    = 512
  memory = 1024
  port   = 3000
  name   = "ecs-sample"
  image  = "public.ecr.aws/aws-containers/ecsdemo-nodejs:c3e96da"
}

# container_sample_entrypoint = ["/.aquasec/bin/microenforcer","bash", "/usr/src/app/startup.sh"]
# container_sample_command    = []
# container_sample_environment = [
#   {
#     name  = "AQUA_MICROENFORCER"
#     value = "1"
#   },
#   {
#     name  = "AQUA_SERVER"
#     value = "xxxxxxx-gw.cloud.aquasec.com:443"
#   },
#   {
#     name  = "AQUA_TOKEN"
#     value = "xxxxxx-xxxxx-xxxxx-xxxxx-xxxxx"
#   },
#   {
#     name  = "AQUA_IMAGE_ID"
#     value = "xxxxx"
#   }
# ]

# container_sample_volumes_from = [{
#   sourceContainer = "aqua-sidecar"
#   readOnly        = false
# }]

################################################################################
# ALB
################################################################################

load_balancer = {
  enable_deletion_protection = false
}

################################################################################
# Networking
################################################################################

network = {
  vpc_cidr                      = "10.0.0.0/16"
  enable_nat_gateway            = true
  single_nat_gateway            = true
  enable_dns_hostnames          = true
  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true
}

################################################################################
# Module - Aquasec
################################################################################

enable_aquasec                        = false
enable_aquasec_sidecar                = false
enable_aquasec_sidecar_ecr_repository = false

aquasec = {
  secret_manager_name = "aquasec"
}

aquasec_microenforcer_sidecar = {
  name               = "aqua-sidecar"
  cpu                = 512
  memory             = 1024
  essential          = false
  image              = "xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest"
  memory_reservation = 50
}


################################################################################
# Module - Datadog
################################################################################

enable_datadog = false

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

################################################################################
# Module - Codepipeline with Github
################################################################################

enable_codepipeline_github = false

repository_name       = "my-example-app"
dockerhub_secret_name = "/apps/docker/credentials"
secret_manager_name   = "github"