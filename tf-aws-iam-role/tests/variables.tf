variable "name" {
  description = "The name of the IAM role"
  type        = string
}

variable "assume_role_services" {
  description = "AWS service principals allowed to assume this role"
  type        = list(string)
}

variable "managed_policy_arns" {
  description = "Managed policies to attach to the role"
  type        = list(string)
}

variable "region" {
  description = "The AWS region where the resource will be created"
  type        = string
}

variable "resource_group_identifier" {
  description = "The AppRef or resource group identifier"
  type        = string
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
