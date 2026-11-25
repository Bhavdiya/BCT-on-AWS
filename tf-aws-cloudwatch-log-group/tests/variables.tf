variable "name" {
  description = "The name of the log group"
  type        = string
}

variable "retention_in_days" {
  description = "How long log events are kept"
  type        = number
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
