module "alb" {
  source = "../"

  name                       = var.name
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  certificate_arn            = var.certificate_arn
  target_port                = var.target_port
  enable_deletion_protection = false
  region                     = var.region
  resource_group_identifier  = var.resource_group_identifier
  resource_tags              = var.resource_tags
}
