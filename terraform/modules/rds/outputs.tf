output "db_instance_id" {
  description = "DB instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "DB instance ARN"
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "Connection endpoint, host and port"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname only"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Listener port"
  value       = aws_db_instance.this.port
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the RDS-managed master credential"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
