variable "name" {
  description = "Name used for the cluster, task family, service and security group"
  type        = string
  default     = "ecs-test-example"
}

variable "vpc_id" {
  description = "VPC the service runs in"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets the tasks are placed in"
  type        = list(string)
}

variable "image" {
  description = "Container image to run, normally an ECR image pinned by digest or immutable tag"
  type        = string
}

variable "execution_role_arn" {
  description = "Role ECS itself assumes to pull the image and read secrets"
  type        = string
}

variable "task_role_arn" {
  description = "Role the application assumes at runtime. This is the managed identity equivalent"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group the container writes to"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Task CPU units. 1024 is one vCPU"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 2048
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64"
  type        = string
  default     = "X86_64"
}

variable "environment" {
  description = "Plain environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables sourced from Secrets Manager or SSM, as name to ARN"
  type        = map(string)
  default     = {}
}

variable "target_group_arn" {
  description = "(Optional) Load balancer target group to register tasks with"
  type        = string
  default     = null
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the container port, normally just the load balancer"
  type        = list(string)
  default     = []
}

variable "min_capacity" {
  description = "Minimum running tasks, also the initial desired count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum running tasks"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Average CPU percentage autoscaling tries to hold"
  type        = number
  default     = 60
}

variable "health_check_command" {
  description = "Shell command the container health check runs"
  type        = string
  default     = "curl -f http://localhost:8080/healthz || exit 1"
}

variable "enable_execute_command" {
  description = "Allow ECS Exec into running tasks. Useful in dev, audit before enabling in production"
  type        = bool
  default     = false
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
