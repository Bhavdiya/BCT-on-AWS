variable "name" {
  description = "The name of the user pool"
  type        = string
}

variable "domain_prefix" {
  description = "Prefix for the hosted UI domain"
  type        = string
}

variable "callback_urls" {
  description = "Redirect URIs the app client may return to after sign in"
  type        = list(string)
}

variable "logout_urls" {
  description = "Redirect URIs allowed after sign out"
  type        = list(string)
}

variable "identity_provider" {
  description = "External IdP to federate with"
  type = object({
    name              = string
    type              = string
    details           = map(string)
    attribute_mapping = map(string)
  })
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
