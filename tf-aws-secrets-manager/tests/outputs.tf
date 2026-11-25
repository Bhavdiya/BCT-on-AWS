output "secret_arn" {
  description = "The ARN of the secret"
  value       = module.secret.secret_arn
}

output "secret_name" {
  description = "The name of the secret"
  value       = module.secret.secret_name
}
