output "distribution_id" {
  description = "The ID of the distribution"
  value       = module.cloudfront.distribution_id
}

output "distribution_arn" {
  description = "The ARN of the distribution"
  value       = module.cloudfront.distribution_arn
}

output "domain_name" {
  description = "The CloudFront domain name"
  value       = module.cloudfront.domain_name
}
