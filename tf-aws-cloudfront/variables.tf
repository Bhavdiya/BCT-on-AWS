variable "name" {
  description = "Identifier used for the distribution comment and origin access control"
  type        = string
  default     = "cdn-test-example"
}

variable "spa_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket holding the built front end"
  type        = string
}

variable "api_domain_name" {
  description = "Domain name of the API origin, normally the load balancer DNS name"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate for the aliases. Must be issued in us-east-1"
  type        = string
}

variable "aliases" {
  description = "Custom domain names served by the distribution"
  type        = list(string)
}

variable "api_path_pattern" {
  description = "Path prefix routed to the API origin instead of the front end"
  type        = string
  default     = "/api/*"
}

variable "web_acl_arn" {
  description = "(Optional) CLOUDFRONT scoped WAFv2 Web ACL ARN"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Which edge locations serve the distribution"
  type        = string
  default     = "PriceClass_All"
}

variable "region" {
  description = "The AWS region where the resource will be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "resource_group_identifier" {
  description = "The AppRef or resource group identifier"
  type        = string
  default     = "APP-1234"
}

variable "resource_tags" {
  type = object({
    tag_env           = string
    tag_business_unit = string
    tag_app_name      = string
    tag_app_owner     = string
  })
  description = "(Required) Standard Tags to Apply"
}

variable "additional_tags" {
  type        = map(string)
  description = "(Optional) Additional tags to apply"
  default     = {}
}
