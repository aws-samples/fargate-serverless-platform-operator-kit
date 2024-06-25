################################################################################
# Outputs
################################################################################

output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = module.ecs.cluster_arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = module.ecs.cluster_name
}

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = module.ecs.cluster_capacity_providers
}

output "cluster_autoscaling_capacity_providers" {
  description = "Map of capacity providers created and their attributes"
  value       = module.ecs.autoscaling_capacity_providers
}

output "ecs_task_execution_role_name" {
  description = "The ARN of the task execution role"
  value       = module.ecs.task_exec_iam_role_name
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the task execution role"
  value       = module.ecs.task_exec_iam_role_arn
}

output "application_url" {
  value       = "http://${module.service_alb.lb_dns_name}"
  description = "Copy this value in your browser in order to access the deployed app"
}
