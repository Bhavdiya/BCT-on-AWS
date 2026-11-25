output "key_id" {
  description = "The key ID"
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "The key ARN"
  value       = aws_kms_key.this.arn
}

output "alias_name" {
  description = "The key alias"
  value       = aws_kms_alias.this.name
}
