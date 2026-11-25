output "user_pool_id" {
  description = "The ID of the user pool"
  value       = module.cognito.user_pool_id
}

output "client_id" {
  description = "App client ID for the OIDC sign in flow"
  value       = module.cognito.client_id
}

output "issuer_url" {
  description = "OIDC issuer the API validates JWTs against"
  value       = module.cognito.issuer_url
}

output "role_group_names" {
  description = "Application role groups that were created"
  value       = module.cognito.role_group_names
}
