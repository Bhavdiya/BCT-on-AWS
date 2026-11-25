module "opensearch" {
  source = "../"

  name                       = var.name
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  master_user_arn            = var.master_user_arn
  instance_type              = var.instance_type
  region                     = var.region
  resource_group_identifier  = var.resource_group_identifier
  resource_tags              = var.resource_tags
}
