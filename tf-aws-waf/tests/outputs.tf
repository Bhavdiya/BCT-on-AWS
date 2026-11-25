output "web_acl_arn" {
  description = "The ARN of the Web ACL"
  value       = module.waf.web_acl_arn
}

output "web_acl_name" {
  description = "The name of the Web ACL"
  value       = module.waf.web_acl_name
}
