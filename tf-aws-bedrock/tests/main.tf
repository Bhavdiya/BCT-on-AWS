module "bedrock" {
  source = "../"

  name                      = var.name
  allowed_model_ids         = var.allowed_model_ids
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
