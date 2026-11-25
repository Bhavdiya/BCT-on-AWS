variable "name_prefix" {
  description = "Name for the load balancer and target group"
  type        = string
}

variable "vpc_id" {
  description = "VPC the target group resolves targets in"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets the load balancer nodes are placed in"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group governing ingress to the load balancer"
  type        = string
}

variable "certificate_arn" {
  description = "(Optional) Regional ACM certificate for the HTTPS listener. Null falls back to an HTTP listener, which is only acceptable behind CloudFront in a non-production environment"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port the API container listens on"
  type        = number
}

variable "health_check_path" {
  description = "Path the target group probes. Must return 200 or the deployment never stabilises"
  type        = string
  default     = "/healthz"
}

variable "health_check_matcher" {
  description = "HTTP codes considered healthy"
  type        = string
  default     = "200"
}

variable "deregistration_delay" {
  description = "Seconds to drain a target before deregistering"
  type        = number
  default     = 30
}

variable "ssl_policy" {
  description = "TLS policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Block deletion of the load balancer through the API"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Write access logs to a dedicated S3 bucket"
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "Days before an access log object expires"
  type        = number
  default     = 90
}

variable "origin_verify_secret" {
  description = "(Optional) Shared header value CloudFront sends and the ALB requires, so the ALB cannot be reached directly even from a CloudFront IP"
  type        = string
  default     = null
  sensitive   = true
}
