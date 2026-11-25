module "cognito" {
  source = "../"

  name                      = var.name
  domain_prefix             = var.domain_prefix
  callback_urls             = var.callback_urls
  logout_urls               = var.logout_urls
  identity_provider         = var.identity_provider
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
