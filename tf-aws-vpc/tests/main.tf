module "vpc" {
  source = "../"

  name                      = var.name
  cidr_block                = var.cidr_block
  az_count                  = var.az_count
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
