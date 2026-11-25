variable "name_prefix" {
  description = "Name for the cluster, task family and service"
  type        = string
}

variable "subnet_ids" {
  description = "Private application subnets the tasks run in"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group applied to the task network interfaces"
  type        = string
}

variable "image" {
  description = "Container image reference. Pin by digest or an immutable tag, never :latest"
  type        = string
}

variable "container_port" {
  description = "Port the API listens on inside the container"
  type        = number
}

variable "execution_role_arn" {
  description = "Role the ECS agent uses to pull the image and resolve secrets"
  type        = string
}

variable "task_role_arn" {
  description = "Role the application assumes at runtime"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group for container stdout"
  type        = string
}

variable "cpu" {
  description = "Task CPU units, 1024 per vCPU"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Task memory in MiB. Must be a valid Fargate pairing with cpu"
  type        = number
  default     = 2048
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64. ARM64 is cheaper but the image must be built for it"
  type        = string
  default     = "X86_64"
}

variable "min_capacity" {
  description = "Minimum task count, also the initial desired count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum task count"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Average CPU percentage the autoscaler holds"
  type        = number
  default     = 60
}

variable "memory_target_value" {
  description = "Average memory percentage the autoscaler holds"
  type        = number
  default     = 75
}

variable "target_group_arn" {
  description = "Target group the service registers tasks into"
  type        = string
}

variable "environment" {
  description = "Non-sensitive environment variables. Never put a credential here, it is visible in the task definition"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables resolved from Secrets Manager at task start, as variable name to secret ARN"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Path the container health check probes"
  type        = string
  default     = "/healthz"
}

variable "enable_container_health_check" {
  description = "Run a health check inside the container. Requires curl in the image"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Allow ECS Exec into running tasks"
  type        = bool
  default     = false
}

variable "enable_xray" {
  description = "Add the X-Ray daemon sidecar. The application must also be instrumented"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable Container Insights metric collection on the cluster"
  type        = bool
  default     = true
}

variable "deployment_min_healthy_percent" {
  description = "Minimum healthy percent during a deployment"
  type        = number
  default     = 100
}

variable "deployment_max_percent" {
  description = "Maximum percent during a deployment"
  type        = number
  default     = 200
}
