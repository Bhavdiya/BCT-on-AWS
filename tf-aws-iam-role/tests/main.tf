module "iam_role" {
  source = "../"

  name                      = var.name
  assume_role_services      = var.assume_role_services
  managed_policy_arns       = var.managed_policy_arns
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
