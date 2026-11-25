output "web_acl_id" {
  description = "The ID of the Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "The ARN of the Web ACL, pass this to an ALB association or a CloudFront distribution"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "The name of the Web ACL"
  value       = aws_wafv2_web_acl.this.name
}
