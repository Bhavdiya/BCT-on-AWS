output "secret_arns" {
  description = "Secret ARNs keyed by short name, for the task definition secrets block"
  value       = { for key, secret in aws_secretsmanager_secret.this : key => secret.arn }
}

output "secret_arn_list" {
  description = "Flat list of secret ARNs, for scoping IAM policies"
  value       = [for secret in aws_secretsmanager_secret.this : secret.arn]
}

output "secret_names" {
  description = "Full secret names"
  value       = { for key, secret in aws_secretsmanager_secret.this : key => secret.name }
}
