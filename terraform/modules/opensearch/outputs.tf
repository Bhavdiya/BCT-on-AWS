output "domain_arn" {
  description = "Domain ARN"
  value       = aws_opensearch_domain.this.arn
}

output "endpoint" {
  description = "VPC endpoint the application queries"
  value       = aws_opensearch_domain.this.endpoint
}

output "domain_name" {
  description = "Domain name"
  value       = aws_opensearch_domain.this.domain_name
}
