variable "name" {
  description = "The name of the AppConfig application"
  type        = string
  default     = "appconfig-test-example"
}

variable "description" {
  description = "What this application's configuration covers"
  type        = string
  default     = "Managed by Terraform"
}

variable "environment_name" {
  description = "The AppConfig environment, normally the deployment environment name"
  type        = string
  default     = "development"
}

variable "profile_type" {
  description = "AWS.AppConfig.FeatureFlags for feature flags, AWS.Freeform for plain settings"
  type        = string
  default     = "AWS.AppConfig.FeatureFlags"
}

variable "deployment_duration_in_minutes" {
  description = "How long a configuration change is rolled out over"
  type        = number
  default     = 10
}

variable "final_bake_time_in_minutes" {
  description = "How long AppConfig monitors alarms after a rollout before marking it complete"
  type        = number
  default     = 5
}

variable "growth_factor" {
  description = "Percentage of targets to receive the change in each rollout step"
  type        = number
  default     = 25
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
