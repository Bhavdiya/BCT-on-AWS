variable "name_prefix" {
  description = "Identifier for the distribution comment and origin access control"
  type        = string
}

variable "spa_bucket_regional_domain_name" {
  description = "Regional domain name of the SPA bucket"
  type        = string
}

variable "spa_bucket_id" {
  description = "SPA bucket name, used to build the origin access control identifier"
  type        = string
}

variable "api_domain_name" {
  description = "Load balancer DNS name serving the API"
  type        = string
}

variable "api_origin_protocol_policy" {
  description = "How CloudFront reaches the API origin. https-only whenever the load balancer has a certificate"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["https-only", "http-only", "match-viewer"], var.api_origin_protocol_policy)
    error_message = "api_origin_protocol_policy must be https-only, http-only or match-viewer."
  }
}

variable "api_path_pattern" {
  description = "Path prefix routed to the API origin rather than the SPA"
  type        = string
  default     = "/api/*"
}

variable "certificate_arn" {
  description = "(Optional) ACM certificate covering the aliases. Must be issued in us-east-1. Null uses the default CloudFront certificate and ignores aliases"
  type        = string
  default     = null
}

variable "aliases" {
  description = "Custom domain names. Requires certificate_arn"
  type        = list(string)
  default     = []
}

variable "web_acl_arn" {
  description = "(Optional) CLOUDFRONT scoped Web ACL"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Edge locations serving the distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "origin_verify_secret" {
  description = "(Optional) Shared header sent to the API origin so the load balancer can reject anything that did not come through CloudFront"
  type        = string
  default     = null
  sensitive   = true
}

variable "log_bucket_domain_name" {
  description = "(Optional) S3 bucket domain for access logs. Requires an ACL-enabled bucket"
  type        = string
  default     = null
}

variable "spa_bucket_arn" {
  description = "SPA bucket ARN. The bucket policy granting CloudFront read is created here, not in the frontend module, because putting it there would create a cycle between the two modules"
  type        = string
}
