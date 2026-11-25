variable "name" {
  description = "The DB instance identifier"
  type        = string
  default     = "rds-test-example"
}

variable "vpc_id" {
  description = "VPC the instance lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the DB subnet group. At least two, in different AZs"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to open a SQL Server connection"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "CMK for storage, the master password secret and performance insights"
  type        = string
}

variable "engine" {
  description = "sqlserver-ex, sqlserver-web, sqlserver-se or sqlserver-ee"
  type        = string
  default     = "sqlserver-se"
}

variable "engine_version" {
  description = "SQL Server engine version"
  type        = string
  default     = "16.00"
}

variable "instance_class" {
  description = "Instance size for the environment"
  type        = string
  default     = "db.t3.xlarge"
}

variable "master_username" {
  description = "Master user name. The password is generated and held in Secrets Manager"
  type        = string
  default     = "bctadmin"
}

variable "allocated_storage" {
  description = "Initial storage in GiB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Ceiling for storage autoscaling in GiB"
  type        = number
  default     = 500
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Days of automated backups to keep"
  type        = number
  default     = 14
}

variable "backup_window" {
  description = "Daily backup window in UTC"
  type        = string
  default     = "17:00-18:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC"
  type        = string
  default     = "sun:18:30-sun:19:30"
}

variable "deletion_protection" {
  description = "Block deletion of the instance through the API"
  type        = bool
  default     = true
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
