module "s3" {
  source = "../"

  name                      = var.name
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
