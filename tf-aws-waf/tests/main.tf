module "waf" {
  source = "../"

  name                      = var.name
  scope                     = var.scope
  rate_limit                = var.rate_limit
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
