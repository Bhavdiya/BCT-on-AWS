variable "name_prefix" {
  description = "Replication group identifier"
  type        = string
}

variable "subnet_ids" {
  description = "Private application subnets for the cache subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group governing access to the cache"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK for encryption at rest"
  type        = string
}

variable "node_type" {
  description = "Cache node size"
  type        = string
  default     = "cache.t4g.small"
}

variable "num_cache_clusters" {
  description = "Nodes in the group. More than one enables automatic failover across AZs"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Valkey engine version. Valkey is the maintained successor to Redis OSS and is wire compatible"
  type        = string
  default     = "8.0"
}

variable "parameter_group_name" {
  description = "Parameter group matching the engine and version"
  type        = string
  default     = "default.valkey8"
}

variable "snapshot_retention_limit" {
  description = "Days of automatic snapshots retained"
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Weekly maintenance window, UTC"
  type        = string
  default     = "sun:09:30-sun:10:30"
}
