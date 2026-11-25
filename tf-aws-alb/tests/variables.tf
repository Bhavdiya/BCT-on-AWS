variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "vpc_id" {
  description = "VPC the load balancer lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets to place the load balancer in"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener"
  type        = string
}

variable "target_port" {
  description = "Port the application containers listen on"
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
