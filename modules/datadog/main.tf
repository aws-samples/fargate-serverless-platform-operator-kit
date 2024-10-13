# Configure the Datadog provider
provider "datadog" {
  api_key = try(jsondecode(aws_secretsmanager_secret_version.datadog_version[0].secret_string)["datadog_api_key"], "datadog_api_key")
  app_key = try(jsondecode(aws_secretsmanager_secret_version.datadog_version[0].secret_string)["datadog_app_key"], "datadog_app_key")
  validate = var.enable_datadog
}

resource "aws_secretsmanager_secret" "datadog" {
  count   = var.enable_datadog ? 1 : 0
  name                    = "datadog"
  description             = "Datadog Secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "datadog_version" {
  count   = var.enable_datadog ? 1 : 0
  secret_id     = aws_secretsmanager_secret.datadog[0].id
  secret_string = jsonencode(var.secret_datadog)
}

data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  count   = var.enable_datadog ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        var.datadog_integration_aws.external_id
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  count   = var.enable_datadog ? 1 : 0
  #checkov:skip=CKV_AWS_111:Datadog required permissions:https://docs.datadoghq.com/integrations/amazon_web_services/#aws-iam-permissions.
  #checkov:skip=CKV_AWS_356:Datadog required permissions:https://docs.datadoghq.com/integrations/amazon_web_services/#aws-iam-permissions.
  statement {
    actions = [
      "apigateway:GET",
      "autoscaling:Describe*",
      "backup:List*",
      "budgets:ViewBudget",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codedeploy:List*",
      "codedeploy:BatchGet*",
      "directconnect:Describe*",
      "dynamodb:List*",
      "dynamodb:Describe*",
      "ec2:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticloadbalancing:Describe*",
      "elasticmapreduce:List*",
      "elasticmapreduce:Describe*",
      "es:ListTags",
      "es:ListDomainNames",
      "es:DescribeElasticsearchDomains",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "health:DescribeEvents",
      "health:DescribeEventDetails",
      "health:DescribeAffectedEntities",
      "kinesis:List*",
      "kinesis:Describe*",
      "lambda:GetPolicy",
      "lambda:List*",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:List*",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "s3:GetBucketLogging",
      "s3:GetBucketLocation",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "ses:Get*",
      "sns:List*",
      "sns:Publish",
      "sqs:ListQueues",
      "states:ListStateMachines",
      "states:DescribeStateMachine",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries"
    ]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "datadog_aws_integration" {
  count   = var.enable_datadog ? 1 : 0
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration[0].json
}

resource "aws_iam_role" "datadog_aws_integration" {
  count   = var.enable_datadog ? 1 : 0
  name               = var.datadog_integration_aws.roleName
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  count   = var.enable_datadog ? 1 : 0
  role       = aws_iam_role.datadog_aws_integration[0].name
  policy_arn = aws_iam_policy.datadog_aws_integration[0].arn
}


# Creating Datadog Alerts

resource "datadog_monitor" "cluster_cpuutilization" {
  count   = var.enable_datadog ? 1 : 0
  name    = "ECS - CPU check"
  type    = "metric alert"
  message = "ECS - CPU is > 80%! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.cluster.cpuutilization{clustername:${var.cluster_name}} > ${var.datadog_integration_aws.alert_cpuutilization_threshold}"

  monitor_thresholds {
    critical = var.datadog_integration_aws.alert_cpuutilization_threshold
  }
}

resource "datadog_monitor" "memory_utilization" {
  count   = var.enable_datadog ? 1 : 0
  name    = "ECS - Memory check"
  type    = "metric alert"
  message = "ECS - MEMORY is > 80%! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.cluster.memory_utilization{clustername:${var.cluster_name}} > ${var.datadog_integration_aws.alert_memory_utilization_threshold}"

  monitor_thresholds {
    critical = var.datadog_integration_aws.alert_memory_utilization_threshold
  }
}

resource "datadog_monitor" "task_pending" {
  count   = var.enable_datadog ? 1 : 0
  name    = "ECS - TaskPending check"
  type    = "metric alert"
  message = "ECS - Task pending is > 0! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.service.pending{clustername:${var.cluster_name}} > 0"

  monitor_thresholds {
    critical = 0
  }
}