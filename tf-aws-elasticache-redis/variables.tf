variable "name" {
  description = "The replication group identifier"
  type        = string
  default     = "redis-test-example"
}

variable "vpc_id" {
  description = "VPC the cluster lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the cache subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the cache"
  type        = list(string)
}

variable "node_type" {
  description = "Cache node size for the environment"
  type        = string
  default     = "cache.t4g.small"
}

variable "num_cache_clusters" {
  description = "Nodes in the replication group. More than one enables automatic failover across AZs"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "parameter_group_name" {
  description = "Parameter group matching the engine version"
  type        = string
  default     = "default.redis7"
}

variable "kms_key_arn" {
  description = "(Optional) CMK for encryption at rest"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "(Optional) Redis AUTH token. Source it from Secrets Manager, never inline"
  type        = string
  default     = null
  sensitive   = true
}

variable "snapshot_retention_limit" {
  description = "Days of automatic snapshots to keep"
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC"
  type        = string
  default     = "sun:19:30-sun:20:30"
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
