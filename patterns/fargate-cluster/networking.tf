module "vpc" {
  #checkov:skip=CKV_AWS_111:IAM Policy for Publish logs to CloudWatch Logs. https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html#flow-logs-iam-role
  #checkov:skip=CKV_AWS_356:IAM Policy for Publish logs to CloudWatch Logs. https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html#flow-logs-iam-role
  #checkov:skip=CKV2_AWS_11:No need for VPC flow logs on this pattern.
  #checkov:skip=CKV2_AWS_19:The EIP is attached to an ELB.
  #checkov:skip=CKV2_AWS_12:Default SG.
  #checkov:skip=CKV2_AWS_5:Default SG.
  #checkov:skip=CKV_TF_1:Using full commit hash generate a bug where the ref is not found on the CI.

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.cluster_name
  cidr = var.network.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.network.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.network.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = var.network.enable_nat_gateway
  single_nat_gateway   = var.network.single_nat_gateway
  enable_dns_hostnames = var.network.enable_dns_hostnames

  # Manage so we can name
  manage_default_network_acl    = var.network.manage_default_network_acl
  default_network_acl_tags      = { Name = "${var.cluster_name}-default" }
  manage_default_route_table    = var.network.manage_default_route_table
  default_route_table_tags      = { Name = "${var.cluster_name}-default" }
  manage_default_security_group = var.network.manage_default_security_group
  default_security_group_tags   = { Name = "${var.cluster_name}-default" }

  tags = var.tags
}