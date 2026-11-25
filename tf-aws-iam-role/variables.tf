variable "name" {
  description = "The name of the IAM role"
  type        = string
  default     = "role-test-example"
}

variable "assume_role_services" {
  description = "AWS service principals allowed to assume this role. Ignored when assume_role_policy_json is set"
  type        = list(string)
  default     = ["ecs-tasks.amazonaws.com"]
}

variable "assume_role_policy_json" {
  description = "(Optional) Full trust policy JSON. Use for OIDC federation or cross-account trust"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Managed policies to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "(Optional) Inline policy JSON for permissions specific to this role"
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "(Optional) Permissions boundary that caps what this role can ever be granted"
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for a role assumption"
  type        = number
  default     = 3600
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
