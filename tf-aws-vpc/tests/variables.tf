variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "How many availability zones to spread subnets across"
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
