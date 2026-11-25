# AWS resource inventory

Every resource `terraform/` creates. This reflects the implementation, not a
target architecture — each row corresponds to a `resource` block in the tree.

**Environment** column: `all` means dev, uat and prod. Counts marked *(×AZ)*
scale with `az_count` (2 in dev/uat, 3 in prod).

---

## Required — created in every environment

### Networking — `modules/networking`

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Network | VPC | `aws_vpc` | Yes | all | Network boundary |
| Network | VPC | `aws_subnet.public` *(×AZ)* | Yes | all | ALB and NAT placement |
| Network | VPC | `aws_subnet.app` *(×AZ)* | Yes | all | ECS tasks, interface endpoints |
| Network | VPC | `aws_subnet.data` *(×AZ)* | Yes | all | RDS subnet group; no internet route |
| Network | VPC | `aws_internet_gateway` | Yes | all | Public subnet egress and ALB ingress |
| Network | VPC | `aws_eip.nat` *(1 or ×AZ)* | Yes | all | NAT gateway addresses |
| Network | VPC | `aws_nat_gateway` *(1 or ×AZ)* | Yes | all | Private egress to Entra and the LLM provider |
| Network | VPC | `aws_route_table.public` | Yes | all | Default route to the IGW |
| Network | VPC | `aws_route_table.private` *(×AZ)* | Yes | all | Default route to the AZ's NAT |
| Network | VPC | `aws_route_table.data` | Yes | all | **No default route** — structural database isolation |
| Network | VPC | `aws_route_table_association` *(3×AZ)* | Yes | all | Bind subnets to route tables |
| Network | PrivateLink | `aws_vpc_endpoint.s3` | Yes | all | Gateway endpoint; ECR layer pulls need it |
| Network | PrivateLink | `aws_vpc_endpoint.interface` *(7–8)* | Yes | all | Keeps AWS data-plane traffic off the NAT |
| Network | VPC | `aws_security_group.endpoints` | Yes | all | 443 from the VPC CIDR to the endpoints |
| Network | VPC | `aws_vpc_security_group_ingress_rule.endpoints_https` | Yes | all | The single endpoint ingress rule |
| Observability | CloudWatch | `aws_cloudwatch_log_group.flow_logs` | Yes | all | VPC flow logs (REJECT traffic) |
| Observability | VPC | `aws_flow_log` | Yes | all | Flow log delivery |
| Security | IAM | `aws_iam_role.flow_logs` + `aws_iam_role_policy` | Yes | all | Flow log delivery permission |

### Security groups — `modules/security`

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Security | VPC | `aws_security_group.alb` | Yes | all | Load balancer ingress boundary |
| Security | VPC | `aws_security_group.ecs` | Yes | all | Task network interfaces |
| Security | VPC | `aws_security_group.rds` | Yes | all | Database; one ingress rule, SG-referenced |
| Security | VPC | `aws_vpc_security_group_ingress_rule.alb_https_cloudfront` | Yes | all | CloudFront managed prefix list only |
| Security | VPC | `aws_vpc_security_group_ingress_rule.ecs_from_alb` | Yes | all | Container port from the ALB SG |
| Security | VPC | `aws_vpc_security_group_ingress_rule.rds_from_ecs` | Yes | all | 1433 from the ECS SG |
| Security | VPC | `aws_vpc_security_group_egress_rule.alb_to_ecs` | Yes | all | Forward to targets |
| Security | VPC | `aws_vpc_security_group_egress_rule.ecs_https` | Yes | all | 443 out — Entra and LLM provider |
| Security | VPC | `aws_vpc_security_group_egress_rule.ecs_to_rds` | Yes | all | Database connections |

### Encryption, secrets, configuration

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Security | KMS | `aws_kms_key` | Yes | all | Platform CMK, rotation enabled |
| Security | KMS | `aws_kms_alias` | Yes | all | Stable alias |
| Security | Secrets Manager | `aws_secretsmanager_secret` *(0–1)* | Conditional | all | Only on the external-LLM path; container only, never a value |
| Config | AppConfig | `aws_appconfig_application` | Yes | all | Settings and flag namespace |
| Config | AppConfig | `aws_appconfig_environment` | Yes | all | Per-environment scope |
| Config | AppConfig | `aws_appconfig_configuration_profile.flags` | Yes | all | Feature flags |
| Config | AppConfig | `aws_appconfig_configuration_profile.settings` | Yes | all | Freeform settings |
| Config | AppConfig | `aws_appconfig_deployment_strategy` | Yes | all | Linear rollout with bake time |

### Identity — `modules/iam`

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Identity | IAM | `aws_iam_role.execution` | Yes | all | ECS agent: image pull, log stream, secret resolution |
| Identity | IAM | `aws_iam_role.task` | Yes | all | **Workload identity — the Managed Identity replacement** |
| Identity | IAM | `aws_iam_role_policy.execution` | Yes | all | Scoped to one repository, one log group, named secrets |
| Identity | IAM | `aws_iam_role_policy.task` | Yes | all | Named secrets, AppConfig, optional X-Ray and ECS Exec |
| Identity | IAM | `aws_iam_role_policy_attachment.bedrock` | Conditional | all | Only when `llm_provider = "bedrock"` |

### Compute and registry

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Registry | ECR | `aws_ecr_repository` | Yes | all | API image; immutable tags, scan on push, CMK |
| Registry | ECR | `aws_ecr_lifecycle_policy` | Yes | all | Expire untagged after 7d, keep 30 images |
| Compute | ECS | `aws_ecs_cluster` | Yes | all | Container Insights enabled |
| Compute | ECS | `aws_ecs_cluster_capacity_providers` | Yes | all | FARGATE default, FARGATE_SPOT available |
| Compute | ECS | `aws_ecs_task_definition` | Yes | all | API container, awslogs, optional X-Ray sidecar |
| Compute | ECS | `aws_ecs_service` | Yes | all | Circuit breaker with automatic rollback |
| Compute | App Auto Scaling | `aws_appautoscaling_target` | Yes | all | Owns desired count after first apply |
| Compute | App Auto Scaling | `aws_appautoscaling_policy.cpu` | Yes | all | Target tracking, 60% CPU |
| Compute | App Auto Scaling | `aws_appautoscaling_policy.memory` | Yes | all | Target tracking, 75% memory |

### Ingress

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Ingress | ELB | `aws_lb` | Yes | all | Application Load Balancer |
| Ingress | ELB | `aws_lb_target_group` | Yes | all | IP targets, health check on `/healthz` |
| Ingress | ELB | `aws_lb_listener.main` | Yes | all | Default action **403** — direct access denied |
| Ingress | ELB | `aws_lb_listener_rule.from_cloudfront` | Yes | all | Forwards only on `X-Origin-Verify` match |
| Ingress | S3 | `aws_s3_bucket.logs` + 4 config resources | Yes | all | ALB access logs, SSE-S3, lifecycle expiry |
| Ingress | CloudFront | `aws_cloudfront_distribution` | Yes | all | Two origins: SPA and API |
| Ingress | CloudFront | `aws_cloudfront_origin_access_control` | Yes | all | SigV4 origin access to the SPA bucket |
| Ingress | WAF | `aws_wafv2_web_acl` | Yes | all | 4 managed rule groups + rate limit (us-east-1) |
| Ingress | — | `random_password.origin_verify` | Yes | all | Shared origin header secret |
| Frontend | S3 | `aws_s3_bucket` + versioning, SSE, PAB, ownership, lifecycle | Yes | all | Private SPA bucket |
| Frontend | S3 | `aws_s3_bucket_policy.spa` | Yes | all | OAC read + deny-insecure-transport |

### Database — `modules/rds`

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Database | RDS | `aws_db_instance` | Yes | all | SQL Server, private, encrypted, `publicly_accessible = false` |
| Database | RDS | `aws_db_subnet_group` | Yes | all | Data-tier subnets |
| Database | RDS | `aws_db_parameter_group` | Yes | all | `rds.force_ssl = 1` |
| Database | IAM | `aws_iam_role.monitoring` + attachment | Yes | all | Enhanced monitoring |

The master credential is **not** a Terraform resource. `manage_master_user_password`
makes RDS create and rotate it in Secrets Manager, so no password ever enters state.

### Observability — `modules/monitoring`

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Observability | CloudWatch | `aws_cloudwatch_log_group.app` | Yes | all | Container stdout, CMK-encrypted |
| Observability | SNS | `aws_sns_topic.alarms` | Yes | all | Alarm fan-out, CMK-encrypted |
| Observability | SNS | `aws_sns_topic_subscription.email` *(0–n)* | Optional | all | Requires per-address confirmation |
| Observability | CloudWatch | `aws_cloudwatch_metric_alarm` ×6 | Yes | all | ECS CPU/memory, ALB 5xx, healthy hosts, RDS CPU/storage |
| Observability | CloudWatch | `aws_cloudwatch_dashboard` | Yes | all | Requests, latency percentiles, utilisation, database |

### AI — `modules/bedrock` (when `llm_provider = "bedrock"`, the default)

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| AI | Bedrock | `aws_bedrock_guardrail` | Yes | all | Content filters, PII anonymisation |
| AI | IAM | `aws_iam_policy.invoke` | Yes | all | InvokeModel scoped to approved models and inference profiles |

---

## Conditional — created only when a domain is configured

Created when both `domain_name` and `hosted_zone_id` are set. All three
environments currently leave them unset, so **none of these appear in the
current plan**.

| Category | AWS Service | Terraform Resource | Required? | Environment | Purpose |
|---|---|---|---|---|---|
| Ingress | ACM | `aws_acm_certificate.regional` | Conditional | all | ALB HTTPS listener |
| Ingress | ACM | `aws_acm_certificate.edge` | Conditional | all | CloudFront viewer cert (us-east-1) |
| Ingress | ACM | `aws_acm_certificate_validation` ×2 | Conditional | all | Blocks until DNS validation completes |
| DNS | Route 53 | `aws_route53_record.*_validation` | Conditional | all | Validation records |
| DNS | Route 53 | `aws_route53_record.app` | Conditional | all | Alias to the distribution |

Without a certificate the ALB listener falls back to HTTP on port 80, reachable
only from CloudFront. Acceptable for dev; **not** for production — see
`security.md`.

## Optional — implemented, disabled by default

Complete modules gated by a flag. At `false` they contribute **zero** resources
to the plan. See ADR-011 and U4–U6.

| Category | AWS Service | Terraform Resource | Flag | Purpose |
|---|---|---|---|---|
| Cache | ElastiCache | `aws_elasticache_replication_group`, `aws_elasticache_subnet_group` | `enable_redis` | Valkey 8, encrypted both ways |
| Cache | VPC | `aws_security_group.redis` + 2 rules | `enable_redis` | Cache access from ECS only |
| Messaging | SQS | `aws_sqs_queue` ×2 per queue, `aws_sqs_queue_redrive_allow_policy` | `enable_messaging` | Queue + DLQ + redrive |
| Messaging | CloudWatch | `aws_cloudwatch_metric_alarm.dlq_depth` | `enable_messaging` | Alarm when the DLQ is non-empty |
| Search | OpenSearch | `aws_opensearch_domain` | `enable_search` | VPC domain, FGAC, IAM-only |
| Search | VPC | `aws_security_group.opensearch` + rule | `enable_search` | Search access from ECS only |
| Tracing | ECS / IAM | X-Ray sidecar container + task-role statements | `enable_xray` | Distributed tracing |

## Optional — CI/CD

Created only when both `github_repository` and `state_bucket_arn` are set, so an
unconfigured deploy cannot produce a permissive trust policy.

| Category | AWS Service | Terraform Resource | Purpose |
|---|---|---|---|
| CI/CD | IAM | `aws_iam_openid_connect_provider.github` | Account-global GitHub OIDC provider |
| CI/CD | IAM | `aws_iam_role.plan` | Plan role, `sub` scoped to the repository |
| CI/CD | IAM | `aws_iam_role.deploy` | Deploy role, `sub` scoped to repo **and** environment |
| CI/CD | IAM | 3 policies + 1 managed attachment | State access, ECR push, S3 sync, invalidation, scoped PassRole |

## Bootstrap — applied once per account

Separate configuration with local state. A stack cannot create the bucket
holding its own state.

| Category | AWS Service | Terraform Resource | Purpose |
|---|---|---|---|
| State | S3 | `aws_s3_bucket.state` | Remote state, `prevent_destroy` |
| State | S3 | versioning, SSE, public access block, TLS-deny policy | State durability and protection |

Locking uses S3 conditional writes (`use_lockfile`). **No DynamoDB table** —
superseded in Terraform 1.10+. ADR-013.

## Future — not implemented

| Capability | Why it is not here |
|---|---|
| Cross-Region DR (snapshot copy, read replica) | RPO/RTO targets not specified. Options in `disaster-recovery.md`. |
| CodeBuild migration runner | The DB is private, so migrations need an in-VPC runner. CI platform unconfirmed (ADR-014). |
| Blue/green deployment (CodeDeploy) | Rolling + circuit breaker covers the requirement. |
| GuardDuty, Security Hub, CloudTrail, AWS Config | Account-level, not per-application-stack. `security.md` classifies them. |
| SES | No evidence the application sends email (U10). |
| Cognito identity pool | Nothing requires browser-side AWS credentials (ADR-005). |
| Object store for user data | No evidence of file storage (U8). |
| Scheduled/background task definitions | No evidence of background jobs (U9). |
