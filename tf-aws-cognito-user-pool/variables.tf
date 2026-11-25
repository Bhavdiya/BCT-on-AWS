variable "name" {
  description = "The name of the user pool"
  type        = string
  default     = "cognito-test-example"
}

variable "domain_prefix" {
  description = "Prefix for the hosted UI domain, must be unique within the region"
  type        = string
  default     = "bct-test-example"
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
  description = "(Optional) External IdP to federate with, normally Entra ID over OIDC or SAML"
  type = object({
    name              = string
    type              = string
    details           = map(string)
    attribute_mapping = map(string)
  })
  default = null
}

variable "role_groups" {
  description = "Application roles created as user pool groups. The IdP group claim maps onto these"
  type        = list(string)
  default = [
    "Contributor",
    "Scorer",
    "FunctionOwner",
    "PortfolioCouncil",
    "ValueAnalyst",
    "Admin",
  ]
}

variable "mfa_configuration" {
  description = "OFF, OPTIONAL or ON. Leave OFF when the external IdP already enforces MFA"
  type        = string
  default     = "OFF"
}

variable "advanced_security_mode" {
  description = "OFF, AUDIT or ENFORCED for threat protection"
  type        = string
  default     = "ENFORCED"
}

variable "generate_secret" {
  description = "Issue a client secret. Required for a confidential server side client, wrong for a browser SPA"
  type        = bool
  default     = true
}

variable "access_token_validity_minutes" {
  description = "Access token lifetime in minutes"
  type        = number
  default     = 60
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
