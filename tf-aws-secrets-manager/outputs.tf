output "secret_id" {
  description = "The ID of the secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "The ARN of the secret, reference this from an ECS task definition secrets block"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "The name of the secret"
  value       = aws_secretsmanager_secret.this.name
}
