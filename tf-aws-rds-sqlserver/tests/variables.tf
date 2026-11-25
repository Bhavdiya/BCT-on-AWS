variable "name" {
  description = "The DB instance identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC the instance lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to open a SQL Server connection"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "CMK for storage and the master password secret"
  type        = string
}

variable "instance_class" {
  description = "Instance size for the environment"
  type        = string
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
