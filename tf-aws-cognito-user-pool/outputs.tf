output "user_pool_id" {
  description = "The ID of the user pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "The ARN of the user pool"
  value       = aws_cognito_user_pool.this.arn
}

output "client_id" {
  description = "App client ID for the OIDC sign in flow"
  value       = aws_cognito_user_pool_client.this.id
}

output "client_secret" {
  description = "App client secret, empty when generate_secret is false"
  value       = aws_cognito_user_pool_client.this.client_secret
  sensitive   = true
}

output "issuer_url" {
  description = "OIDC issuer the API validates JWTs against"
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "hosted_ui_domain" {
  description = "Hosted UI domain for the sign in redirect"
  value       = "${aws_cognito_user_pool_domain.this.domain}.auth.${var.region}.amazoncognito.com"
}

output "role_group_names" {
  description = "Application role groups that were created"
  value       = [for group in aws_cognito_user_group.this : group.name]
}
