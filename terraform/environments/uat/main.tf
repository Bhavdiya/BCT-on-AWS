locals {
  environment = "uat"
}

module "platform" {
  source = "../../modules/platform"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  environment        = local.environment
  project            = var.project
  db_master_username = var.db_master_username

  vpc_cidr           = "10.20.0.0/16"
  az_count           = 2
  single_nat_gateway = true

  task_cpu     = 1024
  task_memory  = 2048
  min_capacity = 2
  max_capacity = 4

  db_instance_class          = "db.t3.xlarge"
  db_allocated_storage       = 100
  db_max_allocated_storage   = 500
  db_multi_az                = false
  db_backup_retention_period = 14
  db_deletion_protection     = true
  db_skip_final_snapshot     = false

  log_retention_days = 90

  # Enforcing here first surfaces false positives before production sees them.
  waf_count_only = false

  enable_execute_command = false

  enable_redis     = false
  enable_messaging = false
  enable_search    = false
}
