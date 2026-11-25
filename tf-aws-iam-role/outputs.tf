output "role_name" {
  description = "The name of the role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "The ARN of the role"
  value       = aws_iam_role.this.arn
}

output "role_unique_id" {
  description = "The stable unique ID of the role"
  value       = aws_iam_role.this.unique_id
}
