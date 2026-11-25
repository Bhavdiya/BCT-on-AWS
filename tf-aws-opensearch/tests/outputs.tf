output "domain_arn" {
  description = "The ARN of the domain"
  value       = module.opensearch.domain_arn
}

output "endpoint" {
  description = "VPC endpoint the application queries"
  value       = module.opensearch.endpoint
}

output "security_group_id" {
  description = "Security group of the domain"
  value       = module.opensearch.security_group_id
}
