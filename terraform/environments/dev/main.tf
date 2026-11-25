locals {
  environment = "dev"
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

  # Networking: two AZs even in dev, because retrofitting a second AZ means
  # re-CIDRing the VPC. One NAT gateway is enough for a non-production egress path.
  vpc_cidr           = "10.10.0.0/16"
  az_count           = 2
  single_nat_gateway = true

  # Sizing: the smallest shape that still exercises the production topology.
  task_cpu     = 512
  task_memory  = 1024
  min_capacity = 1
  max_capacity = 2

  db_instance_class          = "db.t3.large"
  db_allocated_storage       = 20
  db_max_allocated_storage   = 100
  db_multi_az                = false
  db_backup_retention_period = 7
  db_deletion_protection     = false
  db_skip_final_snapshot     = true

  log_retention_days = 30

  # WAF in count mode for the first soak, so a managed rule cannot block
  # legitimate traffic before anyone has seen a false positive.
  waf_count_only = true

  # ECS Exec is useful while the container contract is still being confirmed.
  enable_execute_command = true

  # Optional capabilities stay off until the source code confirms they are used.
  # See ADR-011 and application-discovery.md U4 to U6.
  enable_redis     = false
  enable_messaging = false
  enable_search    = false
}
