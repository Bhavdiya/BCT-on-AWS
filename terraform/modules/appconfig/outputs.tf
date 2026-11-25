output "application_id" {
  description = "AppConfig application ID"
  value       = aws_appconfig_application.this.id
}

output "application_arn" {
  description = "AppConfig application ARN, for scoping the task role"
  value       = aws_appconfig_application.this.arn
}

output "environment_id" {
  description = "AppConfig environment ID"
  value       = aws_appconfig_environment.this.environment_id
}

output "flags_profile_id" {
  description = "Feature flag configuration profile ID"
  value       = aws_appconfig_configuration_profile.flags.configuration_profile_id
}

output "settings_profile_id" {
  description = "Freeform settings configuration profile ID"
  value       = aws_appconfig_configuration_profile.settings.configuration_profile_id
}

output "deployment_strategy_id" {
  description = "Deployment strategy ID"
  value       = aws_appconfig_deployment_strategy.this.id
}
