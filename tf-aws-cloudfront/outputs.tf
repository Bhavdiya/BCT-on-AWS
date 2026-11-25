output "distribution_id" {
  description = "The ID of the distribution, needed to issue cache invalidations at release"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the distribution, pass this to the S3 bucket policy"
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "The CloudFront domain name, use this as a Route 53 alias target"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "Hosted zone ID of the distribution, for a Route 53 alias record"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
