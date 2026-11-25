output "bucket_id" {
  description = "The name of the bucket"
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.s3.bucket_arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name, use this as a CloudFront origin"
  value       = module.s3.bucket_regional_domain_name
}
