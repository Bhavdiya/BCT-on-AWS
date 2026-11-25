output "alb_security_group_id" {
  description = "Security group for the load balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group for the API tasks"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group for the database"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group for the cache, null when disabled"
  value       = try(aws_security_group.redis[0].id, null)
}

output "opensearch_security_group_id" {
  description = "Security group for the search domain, null when disabled"
  value       = try(aws_security_group.opensearch[0].id, null)
}
