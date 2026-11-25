variable "name" {
  description = "The name of the VPC"
  type        = string
  default     = "vpc-test-example"
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC. Subnets are carved out of it with a /24 each"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many availability zones to spread the public and private subnets across"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private subnets get outbound internet (needed to reach an external LLM provider)"
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = "AWS service names to expose as PrivateLink interface endpoints inside the VPC"
  type        = list(string)
  default = [
    "secretsmanager",
    "ssm",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "appconfig",
    "appconfigdata",
    "bedrock-runtime",
  ]
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
