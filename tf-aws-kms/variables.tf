variable "name" {
  description = "Alias name for the key, without the alias/ prefix"
  type        = string
  default     = "kms-test-example"
}

variable "description" {
  description = "What this key protects"
  type        = string
  default     = "Customer-managed key"
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion takes effect"
  type        = number
  default     = 30
}

variable "multi_region" {
  description = "Create a multi-region key (needed for cross-region replicas or a CloudFront-scoped consumer)"
  type        = bool
  default     = false
}

variable "policy" {
  description = "(Optional) Key policy JSON. Null leaves the default policy granting the account root full control"
  type        = string
  default     = null
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
