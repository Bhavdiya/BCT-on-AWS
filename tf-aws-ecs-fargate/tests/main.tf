module "ecs" {
  source = "../"

  name                       = var.name
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  image                      = var.image
  execution_role_arn         = var.execution_role_arn
  task_role_arn              = var.task_role_arn
  log_group_name             = var.log_group_name
  ingress_security_group_ids = var.ingress_security_group_ids
  target_group_arn           = var.target_group_arn
  region                     = var.region
  resource_group_identifier  = var.resource_group_identifier
  resource_tags              = var.resource_tags
}
