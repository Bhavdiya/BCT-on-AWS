output "role_name" {
  description = "The name of the role"
  value       = module.iam_role.role_name
}

output "role_arn" {
  description = "The ARN of the role"
  value       = module.iam_role.role_arn
}
