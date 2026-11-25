# BCT on AWS

Two deliverables live in this repository.

| | What it is | Start here |
|---|---|---|
| **[`terraform/`](terraform/)** | The deployable BCT AWS stack — composition modules plus dev/uat/prod environments. Validated; see [`docs/`](docs/). | [terraform/README.md](terraform/README.md) |
| **[`docs/`](docs/)** | Discovery, service mapping, architecture, resource inventory, ADRs, security, deployment, DR. | [docs/application-discovery.md](docs/application-discovery.md) |
| **`tf-aws-*/`** | A separate per-resource Terraform module library, one directory per resource, mirroring the layout of the organisation's Azure modules. Intended to be published as individual repositories. | the table below |

> **Tagging differs between the two.** `terraform/` carries **no tags at all** —
> they were removed by request (ADR-015), and its identifying values ship as
> placeholders (ADR-016). The `tf-aws-*` library below still implements the full
> standard tag contract, because that contract is the reason those modules exist.
> Nothing in `tf-aws-*` was changed.

> **Important:** the BCT application repository was empty when this work was
> done, so no infrastructure requirement is backed by code evidence. Read
> [docs/application-discovery.md](docs/application-discovery.md) before relying
> on any classification here.

---

# Appendix — per-resource module library

Terraform modules for running the **Business Case Tool (BCT)** on AWS,
laid out the same way as
[`tf-azure-resource-group`](https://gitlab.com/<GITLAB_GROUP>/tf-azure-resource-group):
one resource per repository, root module at the top, a `tests/` harness that
consumes it through `source = "../"`.

## Repository layout

Each `tf-aws-*` directory here is intended to become its own GitLab repository,
mirroring the Azure modules exactly:

```
tf-aws-<resource>/
├── .gitignore
├── .gitlab-ci.yml
├── README.md
├── versions.tf          terraform + required_providers
├── variables.tf         inputs, with defaults
├── main.tf              locals.tags + the resource
├── outputs.tf
└── tests/
    ├── versions.tf      same, plus the provider block
    ├── variables.tf     the same inputs, no defaults
    ├── main.tf          module "<name>" { source = "../" }
    ├── outputs.tf       re-exports the module outputs
    └── terraform.tfvars a working example
```

## Tagging contract

Ported unchanged from the Azure module, with `Location` reading `aws <region>`
instead of `azure <location>`:

| Tag | Source |
|---|---|
| `Created` | `formatdate("YYYY-MM-DD", timestamp())`, stamped once then ignored |
| `AppRef` | `var.resource_group_identifier` |
| `Environment` | `var.resource_tags.tag_env` |
| `Location` | `"aws ${lower(var.region)}"` |
| `BusinessUnit` | `var.resource_tags.tag_business_unit` |
| `ApplicationName` | `var.resource_tags.tag_app_name` |
| `ApplicationOwner` | `var.resource_tags.tag_app_owner` |

Every module merges `var.additional_tags` underneath and carries
`lifecycle { ignore_changes = [tags["Created"]] }`. `prevent_destroy` is set on
the resource group and on the stateful resources only — KMS, S3, RDS and
OpenSearch — so non-data modules stay disposable in dev.

## Service mapping

| BCT requirement | Azure | AWS | Module |
|---|---|---|---|
| Governance boundary | Resource Group | Resource Groups (tag query) | [tf-aws-resource-group](tf-aws-resource-group/) |
| Private network | VNet + Private Endpoints | VPC + PrivateLink endpoints | [tf-aws-vpc](tf-aws-vpc/) |
| Key management | Key Vault (keys) | KMS customer-managed key | [tf-aws-kms](tf-aws-kms/) |
| Secrets | Key Vault (secrets) | Secrets Manager | [tf-aws-secrets-manager](tf-aws-secrets-manager/) |
| Settings + feature flags | App Configuration | AppConfig | [tf-aws-appconfig](tf-aws-appconfig/) |
| Service identity | Managed Identity | IAM role assumed by the task | [tf-aws-iam-role](tf-aws-iam-role/) |
| SSO / OIDC / JWT | Microsoft Entra ID | Cognito user pool federated to Entra | [tf-aws-cognito-user-pool](tf-aws-cognito-user-pool/) |
| Relational database | Azure SQL Database | RDS for SQL Server | [tf-aws-rds-sqlserver](tf-aws-rds-sqlserver/) |
| API + web compute | App Service / AKS | ECS Fargate | [tf-aws-ecs-fargate](tf-aws-ecs-fargate/) |
| Container registry | Azure Container Registry | ECR | [tf-aws-ecr](tf-aws-ecr/) |
| Regional ingress | Application Gateway | Application Load Balancer | [tf-aws-alb](tf-aws-alb/) |
| Global ingress / CDN | Front Door | CloudFront | [tf-aws-cloudfront](tf-aws-cloudfront/) |
| Edge filtering | WAF policy | WAFv2 Web ACL | [tf-aws-waf](tf-aws-waf/) |
| TLS certificates | Key Vault cert / App Service cert | ACM | [tf-aws-acm-certificate](tf-aws-acm-certificate/) |
| Front-end static assets | Blob Storage static website | S3 behind CloudFront OAC | [tf-aws-s3](tf-aws-s3/) |
| Telemetry | Application Insights / Log Analytics | CloudWatch Logs | [tf-aws-cloudwatch-log-group](tf-aws-cloudwatch-log-group/) |
| LLM endpoint | Azure OpenAI | Bedrock (Anthropic Claude) + guardrail | [tf-aws-bedrock](tf-aws-bedrock/) |
| Async / eventing | Service Bus queue | SQS + DLQ | [tf-aws-sqs](tf-aws-sqs/) |
| Cache | Azure Cache for Redis | ElastiCache for Redis | [tf-aws-elasticache-redis](tf-aws-elasticache-redis/) |
| Vector / hybrid search | Azure AI Search | OpenSearch Service | [tf-aws-opensearch](tf-aws-opensearch/) |

### Mappings that are not one-for-one

**Resource Group.** Azure resource groups are a real containment and lifecycle
boundary; AWS Resource Groups are only a saved tag query. Deleting one deletes
nothing. The containment that Azure gets from the resource group has to come
from the account boundary and from `AppRef` + `Environment` tag discipline,
which is why the module builds its query from exactly those two tags.

**Managed Identity → IAM role.** ECS tasks assume `task_role_arn` and get
credentials from the container credential endpoint, so nothing lands in config.
But **RDS for SQL Server does not support IAM database authentication** — that
feature is MySQL, MariaDB and PostgreSQL only. The nearest equivalent is
`manage_master_user_password = true`: RDS generates the password, stores it in
Secrets Manager, rotates it, and the task role is granted read on that secret.
The connection string is still assembled at runtime from a secret rather than a
config file, but it is a credential, not a token. If passwordless auth is a hard
requirement, Aurora PostgreSQL with IAM auth is the alternative — EF Core
supports Npgsql, and the migration cost is in the provider, not the model.

**Entra ID → Cognito.** Cognito is the token issuer the API validates against;
Entra stays the identity source and federates in as an OIDC or SAML provider.
The six application roles are created as user pool groups, and the Entra group
claim maps onto them — the `cognito:groups` claim is what the API authorises on.
Directory and HR hierarchy sync (service line → department → team) is an
application concern either way; neither Entra nor Cognito models it.

**Azure OpenAI → Bedrock.** No endpoint resource to create — access is granted,
not provisioned. The module produces the two things that are actually
deployable: a guardrail, and a least-privilege `InvokeModel` policy scoped to the
approved models. Note that most regions, including `ap-southeast-1`, require a
cross-region **inference profile** ARN rather than the bare foundation model
ARN, so the policy grants both. Model access must still be enabled once per
account in the Bedrock console. If the deployment uses the Anthropic API
directly instead of Bedrock, drop this module, hold the key in
`tf-aws-secrets-manager`, and allow egress on 443 to `api.anthropic.com`.

**App Service deployment slots.** No direct equivalent. ECS gives you rolling
deployments with `deployment_circuit_breaker` for automatic rollback, which
covers the safety property slots are usually used for. Blue/green needs
CodeDeploy, which is not in this set.

**Front Door / Application Gateway.** Azure collapses global and regional
ingress into one product per tier; AWS splits them. CloudFront handles the
global edge, TLS termination and the CLOUDFRONT-scoped WAF; the ALB handles
regional routing, health checks and the REGIONAL-scoped WAF. Both modules exist
because both layers are needed.

## Deployment order

Nothing here is a root module — there is no composition layer in this
repository, by design, matching the Azure repos. A per-environment stack wires
them together in dependency order:

1. `tf-aws-resource-group`, `tf-aws-kms`, `tf-aws-vpc`
2. `tf-aws-ecr`, `tf-aws-s3`, `tf-aws-cloudwatch-log-group`, `tf-aws-secrets-manager`, `tf-aws-appconfig`
3. `tf-aws-rds-sqlserver`, `tf-aws-elasticache-redis`, `tf-aws-opensearch`, `tf-aws-sqs`
4. `tf-aws-cognito-user-pool`, `tf-aws-bedrock`, `tf-aws-iam-role`
5. `tf-aws-acm-certificate`, `tf-aws-waf`, `tf-aws-alb`, `tf-aws-ecs-fargate`
6. `tf-aws-cloudfront`

Two cross-region details: the CloudFront certificate must be issued in
`us-east-1`, and a `CLOUDFRONT`-scoped Web ACL must be created by a provider
aliased to `us-east-1`. Everything else stays in the application region.

## Verification

Every module passes `terraform validate`:

```sh
for m in tf-aws-*; do (cd "$m/tests" && terraform init -backend=false && terraform validate); done
```

The `tests/terraform.tfvars` files use placeholder ARNs and IDs so `validate`
runs without an AWS account. Replace them with real values from the upstream
modules' outputs before running `plan` or `apply`.

## Not included

- Composition / environment root modules — one repo per resource is the convention here.
- `.gitlab-ci.yml` is present but empty, matching the Azure modules.
- Route 53 zones, CodePipeline, and the EF Core migration release job.
