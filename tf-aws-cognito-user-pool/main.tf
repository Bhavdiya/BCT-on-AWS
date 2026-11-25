locals {
  tags = merge(var.additional_tags, {
    Created          = formatdate("YYYY-MM-DD", timestamp())
    AppRef           = var.resource_group_identifier
    Environment      = var.resource_tags["tag_env"]
    Location         = "aws ${lower(var.region)}"
    BusinessUnit     = var.resource_tags["tag_business_unit"]
    ApplicationName  = var.resource_tags["tag_app_name"]
    ApplicationOwner = var.resource_tags["tag_app_owner"]
  })
}

resource "aws_cognito_user_pool" "this" {
  name                = var.name
  mfa_configuration   = var.mfa_configuration
  deletion_protection = "ACTIVE"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 14
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 3
  }

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration == "OFF" ? [] : [1]

    content {
      enabled = true
    }
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_cognito_identity_provider" "this" {
  count = var.identity_provider == null ? 0 : 1

  user_pool_id      = aws_cognito_user_pool.this.id
  provider_name     = var.identity_provider.name
  provider_type     = var.identity_provider.type
  provider_details  = var.identity_provider.details
  attribute_mapping = var.identity_provider.attribute_mapping
}

# One group per application role. Group membership is what the API authorises on,
# so the directory group to role mapping lands here.
resource "aws_cognito_user_group" "this" {
  for_each = toset(var.role_groups)

  name         = each.value
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Application role: ${each.value}"
}

resource "aws_cognito_user_pool_client" "this" {
  name         = var.name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = var.generate_secret
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  supported_identity_providers         = var.identity_provider == null ? ["COGNITO"] : [var.identity_provider.name]

  explicit_auth_flows   = ["ALLOW_REFRESH_TOKEN_AUTH"]
  access_token_validity = var.access_token_validity_minutes
  id_token_validity     = var.access_token_validity_minutes

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [aws_cognito_identity_provider.this]
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
