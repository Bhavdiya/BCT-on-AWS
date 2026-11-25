module "appconfig" {
  source = "../"

  name                      = var.name
  description               = var.description
  environment_name          = var.environment_name
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
