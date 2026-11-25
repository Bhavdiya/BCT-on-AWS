variable "name" {
  description = "The name of the log group"
  type        = string
  default     = "/aws/test-example"
}

variable "retention_in_days" {
  description = "How long log events are kept. 0 means never expire"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "(Optional) CMK to encrypt log data with. The key policy must allow the CloudWatch Logs service"
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
