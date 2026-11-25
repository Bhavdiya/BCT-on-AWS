output "distribution_id" {
  description = "Distribution ID, needed to invalidate the cache at release"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "Distribution ARN, granted read on the SPA bucket"
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront domain name, the Route 53 alias target"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone, for a Route 53 alias record"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
