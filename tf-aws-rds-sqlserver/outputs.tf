output "db_instance_id" {
  description = "The DB instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the DB instance"
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "Connection endpoint, host and port"
  value       = aws_db_instance.this.endpoint
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the rotated master credential"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "Security group of the DB instance"
  value       = aws_security_group.this.id
}
