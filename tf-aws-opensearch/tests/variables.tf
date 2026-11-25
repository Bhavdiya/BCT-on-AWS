variable "name" {
  description = "The domain name"
  type        = string
}

variable "vpc_id" {
  description = "VPC the domain lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the domain"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to query the domain"
  type        = list(string)
}

variable "master_user_arn" {
  description = "IAM principal that is the domain's master user"
  type        = string
}

variable "instance_type" {
  description = "Data node instance type"
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
