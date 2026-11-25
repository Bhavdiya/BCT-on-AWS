output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "The ARN of the task definition currently deployed"
  value       = aws_ecs_task_definition.this.arn
}

output "security_group_id" {
  description = "Security group of the tasks, allow this on the database and cache"
  value       = aws_security_group.this.id
}
