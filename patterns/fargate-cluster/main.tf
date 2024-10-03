################################################################################
# Provider Configuration
################################################################################

provider "aws" {
  region = var.account.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# ECS Cluster Fargate
################################################################################

module "ecs" {
  #checkov:skip=CKV_AWS_111:Task Definition Permissions to Publish logs to CloudWatch Logs and Pull images from Amazon ECR.
  #checkov:skip=CKV_AWS_356:Service Permissions for AutoScaling, CloudWatch Logs and Pull images from Amazon ECR.
  #checkov:skip=CKV2_AWS_5:Default SG.
  #checkov:skip=CKV_TF_1:Using full commit hash generate a bug where the ref is not found on the CI.
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.2"

  cluster_name = var.cluster_name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-fargate"
      }
    }
  }

  cluster_service_connect_defaults = {
    namespace = aws_service_discovery_private_dns_namespace.this.arn
  }

  # Shared task execution role
  create_task_exec_iam_role = false
  # Allow read access to all SSM params in current account for demo
  task_exec_ssm_param_arns = ["arn:aws:ssm:${var.account.region}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  # Allow read access to all secrets in current account for demo
  task_exec_secret_arns = ["arn:aws:secretsmanager:${var.account.region}:${data.aws_caller_identity.current.account_id}:secret:*"]

  # ContainerInsights (https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest#input_cluster_settings)
  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
    #checkov:skip=CKV_AWS_65:Container Insights is enabled by default.
  }

  fargate_capacity_providers = {
    FARGATE      = {}
    FARGATE_SPOT = {}
  }

  services = {
    (var.service_sample.name) = {
      cpu    = var.service_sample.cpu
      memory = var.service_sample.memory

      enable_execute_command = true

      ignore_task_definition_changes = true

      # Container definition(s)
      container_definitions = merge(try({
        #checkov:skip=CKV_AWS_97:EFS is not being used.
        #AquaSec Sidecar
        (var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.name : null) = {
          cpu                = var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.cpu : null
          memory             = var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.memory : null
          essential          = var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.essential : null
          image              = var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.image : null
          memory_reservation = var.enable_aquasec_sidecar == true ? var.aquasec_microenforcer_sidecar.memory_reservation : null
        }
        }, null),
        {
          (var.container_sample.name) = {
            cpu       = var.container_sample.cpu
            memory    = var.container_sample.memory
            essential = true
            image     = var.container_sample.image
            port_mappings = [
              {
                name          = var.container_sample.name
                containerPort = tonumber(var.container_sample.port)
                protocol      = "tcp"
              }
            ]

            #AquaSec App Configuration
            volumes_from = var.container_sample_volumes_from
            entrypoint   = var.container_sample_entrypoint
            command      = var.container_sample_command
            environment  = var.container_sample_environment

            # Example image used requires access to write to root filesystem
            readonly_root_filesystem  = false
            enable_cloudwatch_logging = true
            memory_reservation        = 100
          }
      })

      load_balancer = {
        service = {
          target_group_arn = element(module.service_alb.target_group_arns, 0)
          container_name   = var.container_sample.name
          container_port   = var.container_sample.port
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = var.container_sample.port
          to_port                  = var.container_sample.port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.service_alb.security_group_id
        }
        # TODO limit egress rules
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = var.tags
}

################################################################################
# AWS Service Connect
################################################################################

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "default.${var.cluster_name}.local"
  description = "Service discovery namespace.${var.cluster_name}.local"
  vpc         = module.vpc.vpc_id

  tags = var.tags
}

################################################################################
# ALB Target Group Service Sample
################################################################################

module "service_alb" {
  #checkov:skip=CKV_AWS_91:The access log for the Load Balancer is disabled by default.
  #checkov:skip=CKV2_AWS_28:No need for WAF for this ALB.
  #checkov:skip=CKV_TF_1:Using full commit hash generate a bug where the ref is not found on the CI.
  #checkov:skip=CKV_AWS_91:No need for access logs for the Load Balancer.
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.3"

  name                       = "${var.container_sample.name}-alb"
  load_balancer_type         = "application"
  enable_deletion_protection = var.load_balancer.enable_deletion_protection
  drop_invalid_header_fields = true
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    {
      port               = "80"
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${var.container_sample.name}-alb-tg"
      backend_protocol = "HTTP"
      backend_port     = var.container_sample.port
      target_type      = "ip"
      health_check = {
        path    = "/"
        port    = var.container_sample.port
        matcher = "200-299"
      }
    },
  ]

  tags = var.tags
}

################################################################################
# Module - Datadog
################################################################################

module "datadog" {
  source = "../../modules/datadog"

  enable_datadog = var.enable_datadog

  cluster_name = var.cluster_name

  sns_topic_name_for_alerts = var.sns_topic_name_for_alerts
  datadog_integration_aws   = var.datadog_integration_aws
  secret_datadog         = var.secret_datadog

}

################################################################################
# Module - Codepipeline with Github
################################################################################

# Codepipeline with Github
module "codepipeline_github" {
  count  = var.enable_codepipeline_github ? 1 : 0
  source = "../../modules/codepipeline/github"

  cluster_name = var.cluster_name
  account      = var.account
  account_id   = data.aws_caller_identity.current.account_id

  ecr_repository_name   = var.ecr_repository_name
  repository_name       = var.repository_name
  secret_manager_name   = var.secret_manager_name
  service_sample        = var.service_sample
  container_sample      = var.container_sample
  secret_github         = var.secret_github
}