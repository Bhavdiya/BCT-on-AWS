variable "name" {
  description = "The name of the secret"
  type        = string
  default     = "secret-test-example"
}

variable "description" {
  description = "What this secret holds"
  type        = string
  default     = "Managed by Terraform"
}

variable "kms_key_arn" {
  description = "(Optional) CMK to encrypt the secret with. Null uses the aws/secretsmanager key"
  type        = string
  default     = null
}

variable "initial_value" {
  description = "(Optional) Seed value written once. Subsequent changes are ignored so rotation is not clobbered"
  type        = string
  default     = null
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "How long a deleted secret can be restored. 0 deletes immediately"
  type        = number
  default     = 30
}

variable "rotation_lambda_arn" {
  description = "(Optional) Lambda that rotates the secret. Null disables automatic rotation"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Rotation interval in days when a rotation lambda is configured"
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
