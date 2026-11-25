output "application_url" {
  description = "Public entry point for the application"
  value       = var.domain_name == null ? "https://${module.cloudfront.domain_name}" : "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "Distribution ID, needed by the front-end release job to invalidate the cache"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.cloudfront.domain_name
}

output "spa_bucket" {
  description = "Bucket the built front end is synced into"
  value       = module.frontend.bucket_id
}

output "ecr_repository_url" {
  description = "Repository the API image is pushed to"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name, used by the deploy job"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name, used by the deploy job"
  value       = module.ecs.service_name
}

output "task_definition_family" {
  description = "Task definition family"
  value       = module.ecs.task_definition_family
}

output "alb_dns_name" {
  description = "Load balancer DNS name. Not intended for direct use, the security group only admits CloudFront"
  value       = module.alb.dns_name
}

output "db_endpoint" {
  description = "Database endpoint, reachable only from the application subnets"
  value       = module.rds.endpoint
}

output "db_master_secret_arn" {
  description = "Secrets Manager secret holding the RDS-managed master credential"
  value       = module.rds.master_user_secret_arn
}

output "task_role_arn" {
  description = "Workload identity the application runs as"
  value       = module.iam.task_role_arn
}

output "execution_role_arn" {
  description = "Role the ECS agent uses to pull images and resolve secrets"
  value       = module.iam.execution_role_arn
}

output "kms_key_arn" {
  description = "Platform CMK"
  value       = module.kms.key_arn
}

output "log_group_name" {
  description = "Application log group"
  value       = module.monitoring.log_group_name
}

output "alarm_topic_arn" {
  description = "SNS topic alarms publish to. Subscribers must confirm by email"
  value       = module.monitoring.alarm_topic_arn
}

output "secret_names" {
  description = "Secrets created empty by Terraform. Populate each with put-secret-value before the first deployment"
  value       = module.secrets.secret_names
}

output "bedrock_guardrail_id" {
  description = "Guardrail the application must reference on each InvokeModel call, null on the external LLM path"
  value       = try(module.bedrock[0].guardrail_id, null)
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "app_subnet_ids" {
  description = "Private application subnets, needed by a migration runner task"
  value       = module.networking.app_subnet_ids
}

output "ecs_security_group_id" {
  description = "Task security group, reused by a migration runner so it can reach the database"
  value       = module.security.ecs_security_group_id
}

output "github_plan_role_arn" {
  description = "Role the Terraform plan workflow assumes, null when CI/CD is not configured"
  value       = try(module.cicd[0].plan_role_arn, null)
}

output "github_deploy_role_arn" {
  description = "Role the application deploy workflow assumes, null when CI/CD is not configured"
  value       = try(module.cicd[0].deploy_role_arn, null)
}
