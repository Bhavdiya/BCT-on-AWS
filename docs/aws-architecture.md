# BCT — AWS architecture

The deployed topology, as implemented in `terraform/`. Components the
application has no demonstrated need for are **not** deployed, even where the
brief's baseline diagram shows them; those are listed at the end.

---

## Request path

```
                          Microsoft Entra ID
                     (OIDC issuer — outside AWS,
                      not replaced, see ADR-005)
                                 ▲
                        browser redirects here
                                 │
  Internet ─────────────────────►│
      │
      ▼
  Route 53  (only when a domain is configured; optional)
      │
      ▼
  CloudFront distribution ── AWS WAF (CLOUDFRONT scope, us-east-1)
      │                        managed rules + per-IP rate limit
      │
      ├── default behaviour ──────────────► S3 (private, OAC only)
      │   cache: CachingOptimized              compiled Vite bundle
      │   403/404 → /index.html (SPA routing)
      │
      └── /api/*  ────────────────────────► Application Load Balancer
          cache: disabled                     public subnets
          forwards Authorization              SG: CloudFront prefix list only
          + X-Origin-Verify header            listener default action = 403
                                                        │
                                              forwards only when the
                                              X-Origin-Verify header matches
                                                        │
                                                        ▼
                                              ECS Fargate service
                                              private app subnets
                                              ASP.NET Core 8, port 8080
                                              task role = workload identity
                                                        │
                    ┌───────────────────────────────────┼───────────────────────┐
                    ▼                                   ▼                       ▼
            RDS SQL Server                      Secrets Manager           Bedrock runtime
            private data subnets                  + KMS CMK               via VPC endpoint
            no route to internet               master credential          (or HTTPS egress
            Multi-AZ in prod                    rotated by RDS             to an external
            port 1433 from ECS SG only                                     provider)
                    │
                    └── automated backups, PITR, snapshots

            CloudWatch Logs · Container Insights · alarms → SNS topic
```

## Network layout

Three subnet tiers per availability zone, carved from the VPC CIDR as /20s.

| Tier | Route to internet | Contents |
|---|---|---|
| **public** | IGW, both directions | ALB nodes, NAT gateways |
| **private-app** | outbound via NAT only | ECS tasks, VPC interface endpoints, cache and search when enabled |
| **private-data** | **none at all** | RDS subnet group |

The data tier's route table has no `0.0.0.0/0` entry of any kind — no IGW, no
NAT. There is no network path from a database subnet to the internet or back,
independently of security groups. That is the structural control behind
"RDS must not be publicly accessible"; `publicly_accessible = false` is the
second one.

| Environment | AZs | NAT gateways | VPC CIDR |
|---|---|---|---|
| dev | 2 | 1 | 10.10.0.0/16 |
| uat | 2 | 1 | 10.20.0.0/16 |
| prod | 3 | 3 (one per AZ) | 10.30.0.0/16 |

Non-overlapping CIDRs across environments so any future peering or transit
gateway attachment is possible without renumbering.

### VPC endpoints

Interface endpoints keep the data plane off the NAT path: `secretsmanager`,
`ssm`, `ecr.api`, `ecr.dkr`, `logs`, `appconfig`, `appconfigdata`, and
`bedrock-runtime` when the LLM provider is Bedrock. An S3 **gateway** endpoint
is attached to the private and data route tables — free, and required because
ECR image layers are fetched from S3 rather than through the ECR API endpoint.

The NAT gateway still exists because two required destinations have no
PrivateLink equivalent: the Entra OIDC metadata document and, on the external
LLM path, the provider's public API (ADR-006).

## Security group topology

Every rule is a reference to another security group. Only one CIDR appears
anywhere in the ingress path, and it is on the ALB via a **managed prefix
list**, not a literal.

```
CloudFront origin-facing prefix list ──443/80──► alb-sg
                                                   │
                                          8080 (referenced SG)
                                                   ▼
                                                ecs-sg ──1433──► rds-sg
                                                   │
                                                   └──443──► 0.0.0.0/0
                                                        (egress: Entra + LLM)
```

- `rds-sg` has exactly one ingress rule and it references `ecs-sg`. No CIDR rule
  exists on it, so `0.0.0.0/0` cannot reach 1433 by any configuration path.
- The single `0.0.0.0/0` in the whole stack is an **egress** rule on port 443.
- The ALB additionally requires a shared `X-Origin-Verify` header. The prefix
  list alone is insufficient — it admits every CloudFront customer's traffic,
  including another account's distribution pointed at your ALB. The listener's
  default action is a 403; a rule forwards only on a header match.

## Identity

Two distinct planes, deliberately not merged:

- **User identity — Microsoft Entra ID.** The browser runs the OIDC code flow
  against Entra; the API validates Entra-issued JWTs and authorises on the group
  claim. No AWS identity service participates. Tenant, client ID and audience
  are Terraform variables surfaced as `AzureAd__*` environment variables — they
  are public identifiers, not secrets.
- **Workload identity — IAM.** The ECS task role replaces Managed Identity.
  Separate from the execution role: the execution role pulls images and resolves
  secrets for the agent, the task role is what the application itself assumes.

## Data and encryption

| At rest | Key |
|---|---|
| RDS storage, Performance Insights, master credential secret | customer-managed KMS key |
| S3 (SPA bundle) | SSE-S3 |
| S3 (ALB access logs) | SSE-S3 — the delivery path cannot use a CMK |
| CloudWatch Logs, SNS, ECR, and Secrets Manager | customer-managed KMS key |
| ElastiCache, OpenSearch, SQS (when enabled) | customer-managed KMS key |

In transit: TLS 1.2 minimum at CloudFront; `ELBSecurityPolicy-TLS13-1-2-2021-06`
at the ALB; `rds.force_ssl = 1` in the DB parameter group, which makes the
database refuse any client that will not negotiate TLS; transit encryption
enforced on ElastiCache and OpenSearch.

The CMK's key policy is not the default: it grants the CloudWatch Logs service
principal explicitly (log group creation fails otherwise) and grants the other
services only through a `kms:ViaService` condition scoped to this account.

## Observability

- One log group per environment for container stdout, KMS-encrypted,
  retention 30/90/365 days by environment.
- Container Insights on the cluster.
- VPC flow logs for **rejected** traffic only — the accepted-traffic volume is
  large and rarely read; rejects are what you look at during an incident.
- Alarms: ECS CPU and memory, ALB target 5xx, healthy host count, RDS CPU and
  free storage. All publish to one SNS topic.
- `HealthyHostCount` treats missing data as **breaching**. No data means nothing
  is reporting, which is the outage — treating it as "not breaching" would
  silence the most important alarm in the set.
- A dashboard with request volume, p50/p95/p99 latency, service utilisation and
  database metrics.

## Deliberately not deployed

| Baseline component | Why not |
|---|---|
| ElastiCache | PD-conditional, no code evidence (U4). Module ready, `enable_redis = false`. |
| SQS | PD-conditional, no code evidence (U5). Module ready, `enable_messaging = false`. |
| OpenSearch | PD-conditional, no code evidence (U6). Module ready, `enable_search = false`. |
| Cognito | Rejected on architecture grounds, not cost. ADR-005. |
| Route 53 hosted zone | Records are created only when a zone ID is supplied; the zone itself is a pre-existing organisational asset. |
| X-Ray | Needs application instrumentation. `enable_xray = false`. |
| NAT per AZ in dev/uat | Cost. Production runs one per AZ. |
| GuardDuty, Security Hub, CloudTrail | Account-level controls, not application-stack resources. See `security.md`. |
| Object store for user data | No evidence the application stores files (U8). |

Each is a variable flip, not a rewrite, once the source code confirms the need.
