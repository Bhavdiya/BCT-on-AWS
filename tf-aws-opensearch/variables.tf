variable "name" {
  description = "The domain name"
  type        = string
  default     = "search-test-example"
}

variable "vpc_id" {
  description = "VPC the domain lives in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the domain. Supply as many as instance_count when zone awareness is on"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to query the domain"
  type        = list(string)
}

variable "master_user_arn" {
  description = "IAM principal that is the domain's master user, normally the application task role"
  type        = string
}

variable "engine_version" {
  description = "OpenSearch engine version. 2.x is required for the k-NN vector engine"
  type        = string
  default     = "OpenSearch_2.17"
}

variable "instance_type" {
  description = "Data node instance type"
  type        = string
  default     = "r7g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes. More than one turns on zone awareness"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "EBS volume size per data node in GiB"
  type        = number
  default     = 100
}

variable "kms_key_arn" {
  description = "(Optional) CMK for encryption at rest"
  type        = string
  default     = null
}

variable "access_policies" {
  description = "(Optional) Domain access policy JSON. Null grants only the master user, via fine grained access control"
  type        = string
  default     = null
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
