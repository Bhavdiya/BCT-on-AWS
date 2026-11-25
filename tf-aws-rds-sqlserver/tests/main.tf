module "rds" {
  source = "../"

  name                       = var.name
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  kms_key_arn                = var.kms_key_arn
  instance_class             = var.instance_class
  region                     = var.region
  resource_group_identifier  = var.resource_group_identifier
  resource_tags              = var.resource_tags
}
