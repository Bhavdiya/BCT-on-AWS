module "kms" {
  source = "../"

  name                      = var.name
  description               = var.description
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
