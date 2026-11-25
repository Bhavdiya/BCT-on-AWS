variable "name" {
  description = "Name of the guardrail and the generated invoke policy"
  type        = string
}

variable "allowed_model_ids" {
  description = "Foundation models the application may invoke"
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
