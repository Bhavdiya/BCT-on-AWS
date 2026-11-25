variable "name" {
  description = "Name used for the cluster, task family and service"
  type        = string
}

variable "vpc_id" {
  description = "VPC the service runs in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets the tasks are placed in"
  type        = list(string)
}

variable "image" {
  description = "Container image to run"
  type        = string
}

variable "execution_role_arn" {
  description = "Role ECS assumes to pull the image and read secrets"
  type        = string
}

variable "task_role_arn" {
  description = "Role the application assumes at runtime"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group the container writes to"
  type        = string
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the container port"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Load balancer target group to register tasks with"
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
