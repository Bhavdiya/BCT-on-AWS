variable "name" {
  description = "Identifier used for the distribution comment and origin access control"
  type        = string
}

variable "spa_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket holding the built front end"
  type        = string
}

variable "api_domain_name" {
  description = "Domain name of the API origin"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate issued in us-east-1"
  type        = string
}

variable "aliases" {
  description = "Custom domain names served by the distribution"
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
