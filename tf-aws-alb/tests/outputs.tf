output "dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = module.alb.target_group_arn
}

output "security_group_id" {
  description = "Security group of the load balancer"
  value       = module.alb.security_group_id
}
