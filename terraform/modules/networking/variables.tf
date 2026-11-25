variable "name_prefix" {
  description = "Prefix applied to every resource name, normally <project>-<environment>"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC. Must be large enough for three /20 subnet tiers per AZ"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr must be a valid CIDR of /20 or larger (a smaller prefix number)."
  }
}

variable "az_count" {
  description = "Availability zones to span. Production must be at least 2"
  type        = number

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 4
    error_message = "az_count must be between 1 and 4."
  }
}

variable "public_subnet_cidrs" {
  description = "(Optional) Explicit public subnet CIDRs. Null derives them from vpc_cidr"
  type        = list(string)
  default     = null
}

variable "app_subnet_cidrs" {
  description = "(Optional) Explicit private application subnet CIDRs. Null derives them from vpc_cidr"
  type        = list(string)
  default     = null
}

variable "data_subnet_cidrs" {
  description = "(Optional) Explicit private database subnet CIDRs. Null derives them from vpc_cidr"
  type        = list(string)
  default     = null
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all AZs. Cheaper, but a single point of failure for private egress"
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = "AWS services to expose as PrivateLink interface endpoints, keeping data-plane traffic off the NAT path"
  type        = list(string)
  default = [
    "secretsmanager",
    "ssm",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "appconfig",
    "appconfigdata",
  ]
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for the flow log group"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "(Optional) CMK for flow log encryption"
  type        = string
  default     = null
}
