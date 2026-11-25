output "endpoint" {
  description = "Connection endpoint, host and port"
  value       = module.rds.endpoint
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the rotated master credential"
  value       = module.rds.master_user_secret_arn
}

output "security_group_id" {
  description = "Security group of the DB instance"
  value       = module.rds.security_group_id
}
