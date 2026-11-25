variable "name" {
  description = "Globally unique bucket name"
  type        = string
  default     = "s3-test-example"
}

variable "kms_key_arn" {
  description = "(Optional) CMK to encrypt objects with. Null falls back to SSE-S3"
  type        = string
  default     = null
}

variable "cloudfront_distribution_arn" {
  description = "(Optional) CloudFront distribution allowed to read the bucket through an origin access control"
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "How long superseded object versions are kept before expiring"
  type        = number
  default     = 90
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
