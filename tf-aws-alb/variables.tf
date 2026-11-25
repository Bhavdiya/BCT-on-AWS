variable "name" {
  description = "The name of the load balancer"
  type        = string
  default     = "alb-test-example"
}

variable "vpc_id" {
  description = "VPC the load balancer and target group live in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to place the load balancer in. Public subnets when internal is false"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener"
  type        = string
}

variable "internal" {
  description = "Keep the load balancer off the internet and reachable only from the VPC"
  type        = bool
  default     = false
}

variable "ingress_cidr_blocks" {
  description = "Who may reach the listener. Narrow this when the load balancer is internal or fronted by CloudFront"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_port" {
  description = "Port the application containers listen on"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path the target group probes for health"
  type        = string
  default     = "/healthz"
}

variable "ssl_policy" {
  description = "TLS policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "web_acl_arn" {
  description = "(Optional) WAFv2 Web ACL to associate with the load balancer"
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Block accidental deletion of the load balancer"
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
