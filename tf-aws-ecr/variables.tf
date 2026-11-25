variable "name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "ecr-test-example"
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE. Immutable tags stop a released tag being overwritten"
  type        = string
  default     = "IMMUTABLE"
}

variable "kms_key_arn" {
  description = "(Optional) CMK to encrypt images with. Null uses the AWS managed ECR key"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "How many images to keep before the oldest are expired"
  type        = number
  default     = 30
}

variable "region" {
  description = "The AWS region where the resource will be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "resource_group_identifier" {
  description = "The AppRef or resource group identifier"
  type        = string
  default     = "APP-1234"
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

variable "additional_tags" {
  type        = map(string)
  description = "(Optional) Additional tags to apply"
  default     = {}
}
