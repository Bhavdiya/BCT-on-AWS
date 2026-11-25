module "log_group" {
  source = "../"

  name                      = var.name
  retention_in_days         = var.retention_in_days
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
