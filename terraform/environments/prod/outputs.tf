output "application_url" {
  description = "Public entry point"
  value       = module.platform.application_url
}

output "ecr_repository_url" {
  description = "Repository the API image is pushed to"
  value       = module.platform.ecr_repository_url
}

output "spa_bucket" {
  description = "Bucket the built front end is synced into"
  value       = module.platform.spa_bucket
}

output "cloudfront_distribution_id" {
  description = "Distribution to invalidate on a front-end release"
  value       = module.platform.cloudfront_distribution_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.platform.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.platform.ecs_service_name
}

output "db_endpoint" {
  description = "Database endpoint, private to the VPC"
  value       = module.platform.db_endpoint
}

output "db_master_secret_arn" {
  description = "Secret holding the RDS-managed master credential"
  value       = module.platform.db_master_secret_arn
}

output "secrets_to_populate" {
  description = "Secrets created empty. Populate before the first deployment"
  value       = module.platform.secret_names
}

output "alarm_topic_arn" {
  description = "Alarm topic. Email subscribers must confirm"
  value       = module.platform.alarm_topic_arn
}

output "task_role_arn" {
  description = "Application workload identity"
  value       = module.platform.task_role_arn
}

output "github_plan_role_arn" {
  description = "OIDC role for the Terraform plan workflow"
  value       = module.platform.github_plan_role_arn
}

output "github_deploy_role_arn" {
  description = "OIDC role for the application deploy workflow"
  value       = module.platform.github_deploy_role_arn
}
