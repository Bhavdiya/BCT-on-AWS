# ---------------------------------------------------------------------------
# Identity of the deployment
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Environment name. Drives naming, sizing and every safeguard default"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be dev, uat or prod."
  }
}

variable "project" {
  description = "Short project slug used as the resource name prefix. No default: it must be supplied explicitly"
  type        = string
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Availability zones to span"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "(Optional) Explicit public subnet CIDRs"
  type        = list(string)
  default     = null
}

variable "app_subnet_cidrs" {
  description = "(Optional) Explicit private application subnet CIDRs"
  type        = list(string)
  default     = null
}

variable "data_subnet_cidrs" {
  description = "(Optional) Explicit private database subnet CIDRs"
  type        = list(string)
  default     = null
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs. False gives one per AZ"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send rejected-traffic VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Ingress and DNS
# ---------------------------------------------------------------------------

variable "domain_name" {
  description = "(Optional) Public hostname for the application. Null deploys behind the CloudFront default domain with no custom certificate"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "(Optional) Route 53 zone for certificate validation and the alias record"
  type        = string
  default     = null
}

variable "alb_certificate_arn" {
  description = "(Optional) Pre-existing regional certificate for the load balancer, used instead of issuing one"
  type        = string
  default     = null
}

variable "cloudfront_certificate_arn" {
  description = "(Optional) Pre-existing us-east-1 certificate for CloudFront, used instead of issuing one"
  type        = string
  default     = null
}

variable "cloudfront_price_class" {
  description = "CloudFront edge coverage"
  type        = string
  default     = "PriceClass_100"
}

variable "waf_count_only" {
  description = "Run WAF managed rules in count mode rather than blocking. Use for an initial soak period"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Requests per five minutes from one IP before blocking"
  type        = number
  default     = 2000
}

variable "alb_extra_ingress_cidrs" {
  description = "Extra CIDRs allowed to reach the load balancer directly, for example a corporate test range"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

variable "container_image" {
  description = "Image the ECS service runs. Defaults to a placeholder so the stack can be planned before the first image is built"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port the ASP.NET Core API listens on inside the container. Verify against ASPNETCORE_URLS before the first deploy"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health endpoint path. Verify against the application's MapHealthChecks route before the first deploy"
  type        = string
  default     = "/healthz"
}

variable "api_path_pattern" {
  description = "Path prefix CloudFront routes to the API rather than the SPA"
  type        = string
  default     = "/api/*"
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 2048
}

variable "min_capacity" {
  description = "Minimum running tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum running tasks"
  type        = number
  default     = 10
}

variable "enable_execute_command" {
  description = "Allow ECS Exec into running tasks"
  type        = bool
  default     = false
}

variable "enable_xray" {
  description = "Add the X-Ray sidecar and grant tracing permissions. The application must also be instrumented"
  type        = bool
  default     = false
}

variable "extra_environment" {
  description = "Additional non-sensitive environment variables for the container"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Identity provider. See ADR-005: Entra ID stays the issuer, no Cognito.
# ---------------------------------------------------------------------------

variable "entra_tenant_id" {
  description = "(Optional) Entra directory (tenant) ID. Surfaced to the container as AzureAd__TenantId"
  type        = string
  default     = null
}

variable "entra_client_id" {
  description = "(Optional) Entra application (client) ID for the API app registration. Surfaced as AzureAd__ClientId"
  type        = string
  default     = null
}

variable "entra_audience" {
  description = "(Optional) Expected JWT audience. Surfaced as AzureAd__Audience"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

variable "db_master_username" {
  description = "Database master user name. The password is generated and rotated by RDS, never set here"
  type        = string
}

variable "db_engine" {
  description = "SQL Server edition"
  type        = string
  default     = "sqlserver-se"
}

variable "db_engine_version" {
  description = "SQL Server engine version"
  type        = string
  default     = "16.00"
}

variable "db_instance_class" {
  description = "Database instance size"
  type        = string
  default     = "db.t3.large"
}

variable "db_allocated_storage" {
  description = "Initial database storage in GiB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB"
  type        = number
  default     = 500
}

variable "db_multi_az" {
  description = "Run a synchronous standby with automatic failover"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Days of automated backups"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Block deletion of the database through the API"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Only appropriate for a throwaway environment"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# AI. See ADR-008.
# ---------------------------------------------------------------------------

variable "llm_provider" {
  description = "bedrock uses AWS-native models with IAM authorisation. external provisions a Secrets Manager entry for a third-party provider key and relies on egress"
  type        = string
  default     = "bedrock"

  validation {
    condition     = contains(["bedrock", "external"], var.llm_provider)
    error_message = "llm_provider must be bedrock or external."
  }
}

variable "bedrock_model_ids" {
  description = "Foundation models the task role may invoke"
  type        = list(string)
  default     = ["anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

variable "bedrock_inference_profile_ids" {
  description = "Cross-region inference profiles the task role may invoke"
  type        = list(string)
  default     = ["us.anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

# ---------------------------------------------------------------------------
# Optional capabilities. See ADR-011: all default off, nothing is created until
# the application is confirmed to use them.
# ---------------------------------------------------------------------------

variable "enable_redis" {
  description = "Provision ElastiCache. Turn on only once the code is confirmed to use a distributed cache"
  type        = bool
  default     = false
}

variable "redis_node_type" {
  description = "Cache node size"
  type        = string
  default     = "cache.t4g.small"
}

variable "enable_messaging" {
  description = "Provision SQS queues. Turn on only once the code is confirmed to publish or consume messages"
  type        = bool
  default     = false
}

variable "message_queues" {
  description = "Logical queue names when messaging is enabled"
  type        = list(string)
  default     = ["work"]
}

variable "enable_search" {
  description = "Provision OpenSearch. Turn on only once the code is confirmed to perform vector or hybrid search"
  type        = bool
  default     = false
}

variable "opensearch_instance_type" {
  description = "Search data node instance type"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Search data node count"
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Retention for application and flow log groups"
  type        = number
  default     = 30
}

variable "alarm_email_addresses" {
  description = "Addresses subscribed to the alarm topic"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# CI/CD
# ---------------------------------------------------------------------------

variable "github_repository" {
  description = "(Optional) owner/name of the repository allowed to assume the pipeline roles. Null skips CI/CD role creation entirely, so an unconfigured deploy cannot create a permissive trust policy"
  type        = string
  default     = null
}

variable "create_github_oidc_provider" {
  description = "Create the account-global GitHub OIDC provider. False when one already exists"
  type        = bool
  default     = true
}

variable "state_bucket_arn" {
  description = "(Optional) Terraform state bucket the plan role may access"
  type        = string
  default     = null
}
