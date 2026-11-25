variable "name_prefix" {
  description = "Prefix for role names"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume these roles, as owner/name. The trust policy is scoped to exactly this repository"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form. A wildcard here would let any repository on GitHub assume the role."
  }
}

variable "environment" {
  description = "GitHub environment name gating the deploy role"
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false when one already exists in the account, since it is account-global"
  type        = bool
  default     = true
}

variable "state_bucket_arn" {
  description = "Terraform state bucket the pipeline roles may read and write"
  type        = string
}

variable "ecr_repository_arn" {
  description = "Repository the deploy role may push images to"
  type        = string
}

variable "spa_bucket_arn" {
  description = "SPA bucket the deploy role may sync the built front end into"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "Distribution the deploy role may invalidate"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "Cluster the deploy role may update services in"
  type        = string
}

variable "task_role_arns" {
  description = "Roles the deploy role may pass to ECS. Without an explicit iam:PassRole scope, a deploy role can attach any role in the account to a task"
  type        = list(string)
}
