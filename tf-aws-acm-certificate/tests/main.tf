module "certificate" {
  source = "../"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
