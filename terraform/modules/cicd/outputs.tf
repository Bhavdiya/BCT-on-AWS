output "plan_role_arn" {
  description = "Role the Terraform plan workflow assumes"
  value       = aws_iam_role.plan.arn
}

output "deploy_role_arn" {
  description = "Role the application deployment workflow assumes"
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = local.oidc_provider_arn
}
