variable "name_prefix" {
  description = "Prefix applied to every security group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups belong to"
  type        = string
}

variable "container_port" {
  description = "Port the API container listens on"
  type        = number
}

variable "db_port" {
  description = "Database listener port"
  type        = number
  default     = 1433
}

variable "alb_listener_port" {
  description = "Port the load balancer listener accepts on. 443 when a certificate is configured, otherwise 80"
  type        = number
  default     = 443
}

variable "restrict_alb_to_cloudfront" {
  description = "Limit ALB ingress to CloudFront's origin-facing prefix list. Leave true unless the ALB must be reachable directly"
  type        = bool
  default     = true
}

variable "alb_extra_ingress_cidrs" {
  description = "Additional CIDRs allowed to reach the ALB on 443, for example a corporate egress range for testing"
  type        = list(string)
  default     = []
}

variable "enable_redis" {
  description = "Create the cache security group"
  type        = bool
  default     = false
}

variable "enable_search" {
  description = "Create the search security group"
  type        = bool
  default     = false
}
