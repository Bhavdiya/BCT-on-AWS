output "domain_name" {
  description = "The name of the domain"
  value       = aws_opensearch_domain.this.domain_name
}

output "domain_arn" {
  description = "The ARN of the domain, grant es:ESHttp* on this to the task role"
  value       = aws_opensearch_domain.this.arn
}

output "endpoint" {
  description = "VPC endpoint the application queries"
  value       = aws_opensearch_domain.this.endpoint
}

output "security_group_id" {
  description = "Security group of the domain"
  value       = aws_security_group.this.id
}
