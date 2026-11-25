# BCT — Terraform

AWS infrastructure for the Business Case Tool.

> **Read [`../docs/application-discovery.md`](../docs/application-discovery.md)
> first.** The application repository was empty when this was written, so no
> requirement here is backed by code evidence. Six assumptions are
> deployment-blocking if wrong — they are listed under
> [Verify before the first deploy](#verify-before-the-first-deploy).

---

## Layout

```
terraform/
├── bootstrap/              state bucket; local state, applied once per account
├── modules/
│   ├── platform/           composition module — wires everything together
│   ├── networking/         VPC, 3 subnet tiers, NAT, VPC endpoints, flow logs
│   ├── security/           all security groups and their rules
│   ├── kms/                CMK with a service-scoped key policy
│   ├── secrets/            Secrets Manager containers (never values)
│   ├── iam/                ECS execution role + task role
│   ├── ecr/                image repository and lifecycle policy
│   ├── alb/                load balancer, target group, listener, access logs
│   ├── ecs/                cluster, task definition, service, autoscaling
│   ├── rds/                SQL Server, subnet group, parameter group
│   ├── frontend/           private S3 bucket for the SPA
│   ├── cloudfront/         distribution, OAC, and the SPA bucket policy
│   ├── waf/                WAFv2 Web ACL
│   ├── appconfig/          application, environment, profiles, strategy
│   ├── monitoring/         log group, SNS topic, alarms, dashboard
│   ├── bedrock/            guardrail + least-privilege invoke policy
│   ├── elasticache/        Valkey            (disabled by default)
│   ├── messaging/          SQS + DLQ         (disabled by default)
│   ├── opensearch/         search domain     (disabled by default)
│   └── cicd/               GitHub OIDC provider and pipeline roles
└── environments/
    ├── dev/   uat/   prod/
```

### Why there is a `platform` module

Each environment is ~40 lines that calls `modules/platform` with different
sizing. Without it, three environments would each carry an identical 250-line
composition and drift apart within a quarter. The environment directories hold
only what genuinely differs.

### Relationship to the `tf-aws-*` directories

The `tf-aws-*` directories at the repository root are a **separate deliverable**:
a per-resource module library following the one-repo-per-resource convention
used by the organisation's Azure modules, intended to be published as individual
GitLab repositories.

`terraform/` is the deployable BCT stack. Where the two overlap, **`terraform/`
is the source of truth for this application.** They are not wired together
because the `tf-aws-*` modules are destined for separate repositories, where the
source address becomes a git URL rather than a relative path.

---

## Prerequisites

- Terraform `~> 1.13` — **1.10 minimum**, because state locking uses S3
  conditional writes rather than a DynamoDB table (ADR-013)
- AWS provider `~> 6.0` (6.63.0 pinned in the committed lock files)
- Credentials that can assume an admin-equivalent role for the first apply

---

## Usage

```sh
# once per account
cd bootstrap
terraform init
terraform apply \
  -var "region=<AWS_REGION>" \
  -var "state_bucket_name=<PROJECT_NAME>-tfstate-$(aws sts get-caller-identity --query Account --output text)"

# per environment
cd ../environments/dev
cp backend.hcl.example backend.hcl     # set bucket and region
# then replace the placeholders in terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

Full walkthrough, including seeding the registry and applying migrations, in
[`../docs/deployment.md`](../docs/deployment.md).

### Validating without AWS credentials

```sh
terraform fmt -check -recursive .
for e in dev uat prod; do
  terraform -chdir="environments/$e" init -backend=false
  terraform -chdir="environments/$e" validate
done
```

`terraform plan` needs credentials; `init -backend=false` skips the backend so
`validate` runs offline.

---

## Placeholders to replace

Every value below ships as a placeholder with **no default**, so an unreplaced
one fails at plan time rather than deploying something wrong.

| Placeholder | Where | What to put there |
|---|---|---|
| `<AWS_REGION>` | each `environments/*/terraform.tfvars`, each `backend.hcl` | deployment region, e.g. `us-east-1` |
| `<PROJECT_NAME>` | each `environments/*/terraform.tfvars` | lowercase slug, 2–21 chars, used to build every resource name |
| `<DB_MASTER_USERNAME>` | each `environments/*/terraform.tfvars` | RDS master user; the password is generated and rotated by RDS |
| `<STATE_BUCKET_NAME>` | each `environments/*/backend.hcl` | bucket created by `bootstrap/` |
| `<ACCOUNT_ID>` | `bootstrap/main.tf` header comment | target AWS account |
| `vars.AWS_REGION`, `vars.PROJECT_NAME` | GitHub repository variables | mirror the two tfvars above |

`project` is validated against `^[a-z][a-z0-9-]{1,21}$`, so the literal
`<PROJECT_NAME>` is rejected:

```
Error: Invalid value for variable
  on terraform.tfvars line 6:
   6: project = "<PROJECT_NAME>"
```

That is the intended behaviour, not a bug.

## Consequences of removing tags

Tags were stripped on request. Three consequences are worth knowing before this
reaches production:

1. **No cost allocation.** Cost Explorer cannot break spend down by project,
   environment or owner. Cost data will be available per-service and per-account
   only. Re-adding a `default_tags` block in `environments/*/providers.tf` is the
   one-place fix if that becomes a problem.
2. **Blank names in the console.** VPCs, subnets, route tables, NAT gateways and
   security groups are identified in the AWS console by their `Name` tag. Without
   it they display as blank and must be told apart by ID. Security groups keep
   their `name` attribute, so those remain readable; subnets and route tables do
   not.
3. **Tag-based automation will not match.** Any account-level policy, backup
   plan, SCP condition or Config rule keyed on `Environment` or `Project` will
   not select these resources.

Resource *identifiers* are unaffected — `name_prefix` still produces
`<project>-<environment>` names for the cluster, service, load balancer,
repository, database and log groups.

## Verify before the first deploy

Six assumptions were made because no source code was available. The first three
break the deployment if wrong — the service will never pass a health check and
ECS will roll back forever.

| # | Assumption | Where to confirm | Variable |
|---|---|---|---|
| 1 | Container listens on **8080** | `ASPNETCORE_URLS`, `Dockerfile EXPOSE` | `container_port` |
| 2 | Health endpoint is **`/healthz`** returning 200 | `Program.cs` → `MapHealthChecks` | `health_check_path` |
| 3 | API routes are under **`/api/*`** | controller route attributes | `api_path_pattern` |
| 4 | The app does **not** migrate at startup | `Database.Migrate()` in `Program.cs` | — (ADR-010) |
| 5 | The app is **stateless** — no local disk, no session affinity | `IHostedService`, session config | — |
| 6 | Entra identifiers are supplied | `appsettings.json` → `AzureAd` | `entra_*` |

## Turning on the optional capabilities

Off by default because nothing proves the application uses them (ADR-011). At
`false` each contributes **zero** resources.

| Flag | Turn on when the code shows | Then also |
|---|---|---|
| `enable_redis` | `StackExchange.Redis`, `IDistributedCache` | Read `REDIS_ENDPOINT` |
| `enable_messaging` | a queue client library | Add SQS actions to the task role |
| `enable_search` | a search/vector client | Read `SEARCH_ENDPOINT` |
| `enable_xray` | you want tracing | Instrument with the X-Ray SDK |

## Conventions

- **No resource carries a tag.** Tagging was removed from this stack by request:
  there is no `default_tags` block, no `Name` tag, no cost-allocation tag.
  Resources are still uniquely *named* through `name_prefix`
  (`<project>-<environment>`) wherever the AWS API exposes a name attribute, but
  anything identified only by a tag shows blank in the console. See
  [Consequences of removing tags](#consequences-of-removing-tags).
- **No secret value is ever written by Terraform.** Secrets Manager entries are
  created empty; RDS generates and rotates its own master credential. A value
  passed through Terraform ends up in state as plaintext.
- **Security group rules are separate resources** (`aws_vpc_security_group_*_rule`)
  rather than inline blocks, so groups can reference each other without a cycle.
- **`prevent_destroy` is used once**, on the state bucket. Environment resources
  must stay destroyable; production is protected by `deletion_protection` on the
  database and load balancer instead, which blocks accidental deletion without
  blocking a deliberate teardown.
- **`desired_count` is ignored** after the first apply — the autoscaler owns it.

## Known plan-time behaviour

- `random_password.origin_verify` is the only resource that plans without AWS
  credentials.
- With no `domain_name`, no ACM or Route 53 resources are created and the ALB
  listener runs HTTP on port 80, reachable only from CloudFront. Fine for dev,
  **not for production** — see `../docs/security.md`.
- The ECS service references `<repo>:bootstrap` until a real image is pushed. It
  will not stabilise before then.
