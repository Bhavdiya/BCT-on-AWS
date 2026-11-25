output "web_acl_arn" {
  description = "Web ACL ARN, attached to the CloudFront distribution"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "Web ACL ID"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  description = "Web ACL name, used as a CloudWatch metric dimension"
  value       = aws_wafv2_web_acl.this.name
}
