output "application_id" {
  description = "The ID of the AppConfig application"
  value       = aws_appconfig_application.this.id
}

output "environment_id" {
  description = "The ID of the AppConfig environment"
  value       = aws_appconfig_environment.this.environment_id
}

output "configuration_profile_id" {
  description = "The ID of the configuration profile"
  value       = aws_appconfig_configuration_profile.this.configuration_profile_id
}

output "deployment_strategy_id" {
  description = "The ID of the deployment strategy"
  value       = aws_appconfig_deployment_strategy.this.id
}
