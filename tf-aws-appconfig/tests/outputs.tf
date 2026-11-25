output "application_id" {
  description = "The ID of the AppConfig application"
  value       = module.appconfig.application_id
}

output "environment_id" {
  description = "The ID of the AppConfig environment"
  value       = module.appconfig.environment_id
}

output "configuration_profile_id" {
  description = "The ID of the configuration profile"
  value       = module.appconfig.configuration_profile_id
}
