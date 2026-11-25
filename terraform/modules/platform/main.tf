data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # A certificate is available if one was supplied or if a domain was given for
  # us to issue one against. Without either, the load balancer runs an HTTP
  # listener reachable only from CloudFront.
  issue_certificate = var.domain_name != null && var.hosted_zone_id != null

  # one() yields the single element of a count-indexed list, or null when the
  # count is zero. coalesce() cannot be used here: it raises rather than
  # returning null when every argument is absent, which is the normal state of
  # an environment with no custom domain.
  alb_cert = var.alb_certificate_arn != null ? var.alb_certificate_arn : one(
    aws_acm_certificate_validation.regional[*].certificate_arn
  )

  cloudfront_cert = var.cloudfront_certificate_arn != null ? var.cloudfront_certificate_arn : one(
    aws_acm_certificate_validation.edge[*].certificate_arn
  )

  alb_listener_port = local.alb_cert == null ? 80 : 443

  # The LLM key only exists on the external path; on Bedrock the task role is
  # the credential and there is nothing to store.
  secrets = var.llm_provider == "external" ? {
    "llm-api-key" = "API key for the external LLM provider. Set out of band, never through Terraform."
  } : {}

  enable_cicd = var.github_repository != null && var.state_bucket_arn != null
}

# ---------------------------------------------------------------------------
# Foundation
# ---------------------------------------------------------------------------

module "kms" {
  source = "../kms"

  name_prefix = local.name_prefix
  description = "${local.name_prefix} platform data encryption key"
}

module "networking" {
  source = "../networking"

  name_prefix             = local.name_prefix
  vpc_cidr                = var.vpc_cidr
  az_count                = var.az_count
  public_subnet_cidrs     = var.public_subnet_cidrs
  app_subnet_cidrs        = var.app_subnet_cidrs
  data_subnet_cidrs       = var.data_subnet_cidrs
  single_nat_gateway      = var.single_nat_gateway
  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.log_retention_days
  kms_key_arn             = module.kms.key_arn

  interface_endpoints = concat(
    ["secretsmanager", "ssm", "ecr.api", "ecr.dkr", "logs", "appconfig", "appconfigdata"],
    var.llm_provider == "bedrock" ? ["bedrock-runtime"] : [],
  )
}

module "security" {
  source = "../security"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  container_port             = var.container_port
  alb_listener_port          = local.alb_listener_port
  alb_extra_ingress_cidrs    = var.alb_extra_ingress_cidrs
  restrict_alb_to_cloudfront = true
  enable_redis               = var.enable_redis
  enable_search              = var.enable_search
}

# ---------------------------------------------------------------------------
# Certificates. The edge certificate must live in us-east-1 no matter which
# region the rest of the stack runs in.
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "regional" {
  count = local.issue_certificate && var.alb_certificate_arn == null ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "regional_validation" {
  for_each = {
    for option in try(aws_acm_certificate.regional[0].domain_validation_options, []) :
    option.domain_name => option
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "regional" {
  count = local.issue_certificate && var.alb_certificate_arn == null ? 1 : 0

  certificate_arn         = aws_acm_certificate.regional[0].arn
  validation_record_fqdns = [for record in aws_route53_record.regional_validation : record.fqdn]
}

resource "aws_acm_certificate" "edge" {
  count    = local.issue_certificate && var.cloudfront_certificate_arn == null ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "edge_validation" {
  for_each = {
    for option in try(aws_acm_certificate.edge[0].domain_validation_options, []) :
    "edge-${option.domain_name}" => option
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "edge" {
  count    = local.issue_certificate && var.cloudfront_certificate_arn == null ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.edge[0].arn
  validation_record_fqdns = [for record in aws_route53_record.edge_validation : record.fqdn]
}

# ---------------------------------------------------------------------------
# Registry, configuration, secrets, observability
# ---------------------------------------------------------------------------

module "ecr" {
  source = "../ecr"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.key_arn
}

module "appconfig" {
  source = "../appconfig"

  name_prefix = local.name_prefix
  environment = var.environment
}

module "secrets" {
  source = "../secrets"

  name_prefix             = local.name_prefix
  kms_key_arn             = module.kms.key_arn
  secrets                 = local.secrets
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
}

module "monitoring" {
  source = "../monitoring"

  name_prefix           = local.name_prefix
  log_retention_days    = var.log_retention_days
  kms_key_arn           = module.kms.key_arn
  alarm_email_addresses = var.alarm_email_addresses

  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  alb_arn_suffix          = module.alb.load_balancer_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  db_instance_id          = module.rds.db_instance_id
}

# ---------------------------------------------------------------------------
# AI
# ---------------------------------------------------------------------------

module "bedrock" {
  count  = var.llm_provider == "bedrock" ? 1 : 0
  source = "../bedrock"

  name_prefix                   = local.name_prefix
  allowed_model_ids             = var.bedrock_model_ids
  allowed_inference_profile_ids = var.bedrock_inference_profile_ids
}

# ---------------------------------------------------------------------------
# Identity and permissions
# ---------------------------------------------------------------------------

module "iam" {
  source = "../iam"

  name_prefix        = local.name_prefix
  log_group_arn      = module.monitoring.log_group_arn
  kms_key_arn        = module.kms.key_arn
  ecr_repository_arn = module.ecr.repository_arn

  # The RDS-managed master credential is added to the readable set so the
  # application can build its connection string at runtime.
  secret_arns = concat(
    module.secrets.secret_arn_list,
    [module.rds.master_user_secret_arn],
  )

  appconfig_application_arn = module.appconfig.application_arn
  bedrock_policy_arn        = var.llm_provider == "bedrock" ? module.bedrock[0].invoke_policy_arn : null
  enable_xray               = var.enable_xray
  enable_execute_command    = var.enable_execute_command
}

# ---------------------------------------------------------------------------
# Data tier
# ---------------------------------------------------------------------------

module "rds" {
  source = "../rds"

  name_prefix       = local.name_prefix
  subnet_ids        = module.networking.data_subnet_ids
  security_group_id = module.security.rds_security_group_id
  kms_key_arn       = module.kms.key_arn

  master_username         = var.db_master_username
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
}

module "elasticache" {
  count  = var.enable_redis ? 1 : 0
  source = "../elasticache"

  name_prefix       = local.name_prefix
  subnet_ids        = module.networking.app_subnet_ids
  security_group_id = module.security.redis_security_group_id
  kms_key_arn       = module.kms.key_arn
  node_type         = var.redis_node_type
}

module "messaging" {
  count  = var.enable_messaging ? 1 : 0
  source = "../messaging"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.key_arn
  queues      = var.message_queues
}

module "opensearch" {
  count  = var.enable_search ? 1 : 0
  source = "../opensearch"

  name_prefix       = local.name_prefix
  subnet_ids        = module.networking.app_subnet_ids
  security_group_id = module.security.opensearch_security_group_id
  kms_key_arn       = module.kms.key_arn
  master_user_arn   = module.iam.task_role_arn
  instance_type     = var.opensearch_instance_type
  instance_count    = var.opensearch_instance_count
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

# CloudFront's origin-facing prefix list admits every CloudFront customer, so a
# shared header proves the request came from our distribution specifically.
resource "random_password" "origin_verify" {
  length  = 48
  special = false
}

module "waf" {
  source = "../waf"
  providers = {
    aws = aws.us_east_1
  }

  name_prefix = local.name_prefix
  scope       = "CLOUDFRONT"
  rate_limit  = var.waf_rate_limit
  count_only  = var.waf_count_only
}

module "alb" {
  source = "../alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  certificate_arn   = local.alb_cert
  container_port    = var.container_port
  health_check_path = var.health_check_path

  enable_deletion_protection = var.environment == "prod"
  access_log_retention_days  = var.log_retention_days
  origin_verify_secret       = random_password.origin_verify.result
}

module "frontend" {
  source = "../frontend"

  name_prefix = local.name_prefix
}

module "cloudfront" {
  source = "../cloudfront"

  name_prefix                     = local.name_prefix
  spa_bucket_regional_domain_name = module.frontend.bucket_regional_domain_name
  spa_bucket_id                   = module.frontend.bucket_id
  spa_bucket_arn                  = module.frontend.bucket_arn

  api_domain_name            = module.alb.dns_name
  api_origin_protocol_policy = module.alb.listener_protocol
  api_path_pattern           = var.api_path_pattern

  certificate_arn      = local.cloudfront_cert
  aliases              = var.domain_name == null ? [] : [var.domain_name]
  web_acl_arn          = module.waf.web_acl_arn
  price_class          = var.cloudfront_price_class
  origin_verify_secret = random_password.origin_verify.result
}

resource "aws_route53_record" "app" {
  count = local.issue_certificate ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

module "ecs" {
  source = "../ecs"

  name_prefix       = local.name_prefix
  subnet_ids        = module.networking.app_subnet_ids
  security_group_id = module.security.ecs_security_group_id

  # A placeholder keeps the stack plannable before the first image exists. The
  # deploy pipeline replaces it and Terraform stops managing the tag thereafter.
  image = coalesce(var.container_image, "${module.ecr.repository_url}:bootstrap")

  container_port     = var.container_port
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = module.monitoring.log_group_name
  target_group_arn   = module.alb.target_group_arn
  health_check_path  = var.health_check_path

  cpu          = var.task_cpu
  memory       = var.task_memory
  min_capacity = var.min_capacity
  max_capacity = var.max_capacity

  enable_execute_command = var.enable_execute_command
  enable_xray            = var.enable_xray

  environment = merge(
    {
      ASPNETCORE_ENVIRONMENT     = var.environment
      ASPNETCORE_URLS            = "http://+:${var.container_port}"
      AWS_REGION                 = data.aws_region.current.region
      APPCONFIG_APPLICATION      = module.appconfig.application_id
      APPCONFIG_ENVIRONMENT      = module.appconfig.environment_id
      APPCONFIG_FLAGS_PROFILE    = module.appconfig.flags_profile_id
      APPCONFIG_SETTINGS_PROFILE = module.appconfig.settings_profile_id
      DB_HOST                    = module.rds.address
      DB_PORT                    = tostring(module.rds.port)
      DB_SECRET_ARN              = module.rds.master_user_secret_arn
    },
    # Entra identifiers are not secrets: a tenant ID and a public client ID are
    # both discoverable from the sign-in flow.
    var.entra_tenant_id == null ? {} : { AzureAd__TenantId = var.entra_tenant_id },
    var.entra_client_id == null ? {} : { AzureAd__ClientId = var.entra_client_id },
    var.entra_audience == null ? {} : { AzureAd__Audience = var.entra_audience },
    var.llm_provider == "bedrock" ? {
      LLM_PROVIDER              = "bedrock"
      BEDROCK_GUARDRAIL         = try(module.bedrock[0].guardrail_id, "")
      BEDROCK_GUARDRAIL_VERSION = try(module.bedrock[0].guardrail_version, "")
    } : { LLM_PROVIDER = "external" },
    var.enable_redis ? { REDIS_ENDPOINT = module.elasticache[0].primary_endpoint_address } : {},
    var.enable_search ? { SEARCH_ENDPOINT = module.opensearch[0].endpoint } : {},
    var.enable_messaging ? { QUEUE_URLS = jsonencode(module.messaging[0].queue_urls) } : {},
    var.extra_environment,
  )

  # Resolved from Secrets Manager by the ECS agent at task start, so the value
  # never appears in the task definition.
  secrets = module.secrets.secret_arns
}

# ---------------------------------------------------------------------------
# CI/CD
# ---------------------------------------------------------------------------

module "cicd" {
  count  = local.enable_cicd ? 1 : 0
  source = "../cicd"

  name_prefix          = local.name_prefix
  github_repository    = var.github_repository
  environment          = var.environment
  create_oidc_provider = var.create_github_oidc_provider
  state_bucket_arn     = var.state_bucket_arn

  ecr_repository_arn          = module.ecr.repository_arn
  spa_bucket_arn              = module.frontend.bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  ecs_cluster_arn             = module.ecs.cluster_arn
  task_role_arns              = [module.iam.task_role_arn, module.iam.execution_role_arn]
}
