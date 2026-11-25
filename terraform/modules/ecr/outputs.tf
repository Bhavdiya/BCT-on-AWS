output "repository_url" {
  description = "URL to push images to"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "Repository ARN, for scoping the execution role"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Repository name"
  value       = aws_ecr_repository.this.name
}
