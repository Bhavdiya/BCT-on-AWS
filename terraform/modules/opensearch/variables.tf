variable "name_prefix" {
  description = "Domain name. Must be lowercase and no more than 28 characters"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.name_prefix))
    error_message = "OpenSearch domain names must be lowercase, start with a letter, and be 3 to 28 characters."
  }
}

variable "subnet_ids" {
  description = "Private application subnets for the domain"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group governing access to the domain"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK for encryption at rest"
  type        = string
}

variable "master_user_arn" {
  description = "IAM principal that is the domain master user, normally the ECS task role"
  type        = string
}

variable "engine_version" {
  description = "Engine version. 2.x is required for the k-NN vector engine"
  type        = string
  default     = "OpenSearch_2.17"
}

variable "instance_type" {
  description = "Data node instance type"
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "Data node count. More than one enables zone awareness"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "EBS volume size per node in GiB"
  type        = number
  default     = 50
}
