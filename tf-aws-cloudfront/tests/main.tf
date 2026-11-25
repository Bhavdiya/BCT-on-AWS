module "cloudfront" {
  source = "../"

  name                            = var.name
  spa_bucket_regional_domain_name = var.spa_bucket_regional_domain_name
  api_domain_name                 = var.api_domain_name
  certificate_arn                 = var.certificate_arn
  aliases                         = var.aliases
  region                          = var.region
  resource_group_identifier       = var.resource_group_identifier
  resource_tags                   = var.resource_tags
}
