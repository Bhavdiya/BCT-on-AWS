variable "name" {
  description = "The replication group identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the cache subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the cache"
  type        = list(string)
}

variable "node_type" {
  description = "Cache node size for the environment"
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
