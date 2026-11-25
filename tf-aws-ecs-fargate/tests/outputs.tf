output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "service_name" {
  description = "The name of the ECS service"
  value       = module.ecs.service_name
}

output "security_group_id" {
  description = "Security group of the tasks"
  value       = module.ecs.security_group_id
}
