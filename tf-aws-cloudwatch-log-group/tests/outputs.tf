output "log_group_name" {
  description = "The name of the log group"
  value       = module.log_group.log_group_name
}

output "log_group_arn" {
  description = "The ARN of the log group"
  value       = module.log_group.log_group_arn
}
