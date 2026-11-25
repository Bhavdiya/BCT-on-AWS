output "repository_name" {
  description = "The name of the repository"
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "The ARN of the repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "The URL to push images to"
  value       = aws_ecr_repository.this.repository_url
}
