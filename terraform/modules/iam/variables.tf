variable "name_prefix" {
  description = "Prefix for role and policy names"
  type        = string
}

variable "log_group_arn" {
  description = "Log group the execution role may write to"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK the task must decrypt with to read secrets"
  type        = string
}

variable "secret_arns" {
  description = "Exact secret ARNs the task may read. Empty means no secret access is granted"
  type        = list(string)
  default     = []
}

variable "ecr_repository_arn" {
  description = "Repository the execution role may pull from"
  type        = string
}

variable "appconfig_application_arn" {
  description = "(Optional) AppConfig application the task may read configuration from"
  type        = string
  default     = null
}

variable "bedrock_policy_arn" {
  description = "(Optional) Bedrock invoke policy to attach to the task role"
  type        = string
  default     = null
}

variable "enable_xray" {
  description = "Grant the task permission to publish X-Ray segments"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Grant the SSM channel permissions that ECS Exec requires"
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "(Optional) Boundary capping what these roles can ever be granted"
  type        = string
  default     = null
}
