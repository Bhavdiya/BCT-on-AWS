variable "name_prefix" {
  description = "AppConfig application name"
  type        = string
}

variable "environment" {
  description = "Environment name, becomes the AppConfig environment"
  type        = string
}

variable "deployment_duration_in_minutes" {
  description = "How long a configuration change rolls out over"
  type        = number
  default     = 10
}

variable "final_bake_time_in_minutes" {
  description = "How long AppConfig watches alarms after rollout before completing"
  type        = number
  default     = 5
}

variable "growth_factor" {
  description = "Percent of targets receiving the change in each step"
  type        = number
  default     = 25
}
