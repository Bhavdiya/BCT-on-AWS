output "key_id" {
  description = "The ID of the KMS key"
  value       = module.kms.key_id
}

output "key_arn" {
  description = "The ARN of the KMS key"
  value       = module.kms.key_arn
}

output "alias_name" {
  description = "The alias of the KMS key"
  value       = module.kms.alias_name
}
