variable "domain_name" {
  description = "The fully qualified domain name the certificate is issued for"
  type        = string
  default     = "bct.test.example.com"
}

variable "subject_alternative_names" {
  description = "Additional names covered by the certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "(Optional) Route 53 zone to publish validation records into. Null leaves validation to whoever runs DNS"
  type        = string
  default     = null
}

variable "key_algorithm" {
  description = "Key algorithm for the certificate"
  type        = string
  default     = "RSA_2048"
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
