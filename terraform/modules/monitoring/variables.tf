variable "name_prefix" {
  description = "Prefix for log groups, alarms and the dashboard"
  type        = string
}

variable "log_retention_days" {
  description = "Retention for the application log group"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "CMK for log encryption. The key policy must allow the CloudWatch Logs service"
  type        = string
}

variable "alarm_email_addresses" {
  description = "Addresses subscribed to the alarm topic. Each requires a one-time confirmation click"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_name" {
  description = "(Optional) ECS cluster to alarm on. Null skips the ECS alarms"
  type        = string
  default     = null
}

variable "ecs_service_name" {
  description = "(Optional) ECS service to alarm on"
  type        = string
  default     = null
}

variable "alb_arn_suffix" {
  description = "(Optional) Load balancer ARN suffix to alarm on"
  type        = string
  default     = null
}

variable "target_group_arn_suffix" {
  description = "(Optional) Target group ARN suffix to alarm on"
  type        = string
  default     = null
}

variable "db_instance_id" {
  description = "(Optional) DB instance identifier to alarm on"
  type        = string
  default     = null
}

variable "cpu_alarm_threshold" {
  description = "Average CPU percent that triggers the compute alarm"
  type        = number
  default     = 85
}

variable "memory_alarm_threshold" {
  description = "Average memory percent that triggers the compute alarm"
  type        = number
  default     = 85
}

variable "http_5xx_threshold" {
  description = "Target 5xx responses in five minutes that trigger the error alarm"
  type        = number
  default     = 10
}

variable "db_free_storage_bytes_threshold" {
  description = "Free storage in bytes below which the database alarm fires. Default is 10 GiB"
  type        = number
  default     = 10737418240
}

variable "create_dashboard" {
  description = "Create a CloudWatch dashboard summarising the service"
  type        = bool
  default     = true
}
