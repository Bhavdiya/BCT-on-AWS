locals {
  environment = "prod"
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

  # Three AZs and a NAT per AZ: a single NAT would make private egress, which
  # includes the LLM call path, dependent on one availability zone.
  vpc_cidr           = "10.30.0.0/16"
  az_count           = 3
  single_nat_gateway = false

  # Sizing is a placeholder until real load data exists. See U14.
  task_cpu     = 2048
  task_memory  = 4096
  min_capacity = 3
  max_capacity = 20

  db_instance_class          = "db.r6i.xlarge"
  db_allocated_storage       = 200
  db_max_allocated_storage   = 2000
  db_multi_az                = true
  db_backup_retention_period = 35
  db_deletion_protection     = true
  db_skip_final_snapshot     = false

  log_retention_days = 365

  waf_count_only         = false
  enable_execute_command = false

  cloudfront_price_class = "PriceClass_All"

  enable_redis     = false
  enable_messaging = false
  enable_search    = false

  # Populate before the first production apply so alarms reach a human.
  alarm_email_addresses = []
}
