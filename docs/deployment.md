# Deployment

---

## Manual AWS prerequisites

None of these can be done by Terraform. All must be complete before the first
apply of an environment.

| # | Prerequisite | Why Terraform cannot do it |
|---|---|---|
| 1 | An AWS account and a credential able to assume an admin-equivalent role | Bootstrapping problem |
| 2 | **Bedrock model access enabled** for the Anthropic models, once per account, in the console under *Bedrock → Model access* | No API or Terraform resource exists for the request-access flow |
| 3 | Confirm the correct **inference profile ID** for the region. In us-east-1 newer Anthropic models are reachable only through `us.anthropic.*`, not the bare model ID | Availability varies by region and changes over time |
| 4 | A Route 53 hosted zone, if a custom domain is wanted | Zone delegation is a registrar action |
| 5 | Entra tenant ID, API app registration client ID, and audience | Organisational identity configuration |
| 6 | Entra group → application role mapping for the six roles | Application-side authorization |
| 7 | SNS alarm email subscriptions must be **confirmed** by each recipient | AWS requires a click in the confirmation email |
| 8 | GitHub environments (`dev`, `uat`, `prod`, `prod-database`) with required reviewers | GitHub configuration, not AWS |
| 9 | Populate any Secrets Manager secret listed in the `secrets_to_populate` output | Deliberate: a value passed through Terraform is written to state in plaintext |

## Required inputs with no default

The stack plans without them, but the deployment is not correct until they are
supplied. Set them in the environment's `terraform.tfvars` or in `main.tf`.

| Variable | Consequence if unset |
|---|---|
| `entra_tenant_id`, `entra_client_id`, `entra_audience` | The API cannot validate tokens; every request is 401 |
| `domain_name` + `hosted_zone_id` | No TLS to the origin; CloudFront default domain only |
| `alarm_email_addresses` | Alarms fire into a topic with no subscribers |
| `github_repository` + `state_bucket_arn` | No CI/CD roles are created |
| `container_image` | A `:bootstrap` placeholder tag is used, which will not pull until an image exists |

---

## First deployment

### 1. Create the state bucket, once per account

```sh
cd terraform/bootstrap
terraform init
terraform apply -var "state_bucket_name=bct-tfstate-$(aws sts get-caller-identity --query Account --output text)"
```

Record the `state_bucket_name` and `state_bucket_arn` outputs.

### 2. Point the environment at it

```sh
cd ../environments/dev
cp backend.hcl.example backend.hcl
# edit backend.hcl: bucket = "<the name from step 1>"
```

`backend.hcl` is gitignored — it carries an account-specific value.

### 3. Initialise, review, apply

```sh
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive ../..
terraform validate
terraform plan -out=tfplan          # READ THIS BEFORE CONTINUING
terraform apply tfplan
```

**Read the plan.** Confirm: nothing is destroyed, no security group has a
`0.0.0.0/0` ingress rule, `publicly_accessible` is `false`, and no secret value
appears in the diff.

### 4. Seed the registry

The ECS service references `<repo>:bootstrap` until a real image exists. The
service will not stabilise until one is pushed:

```sh
ECR=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password | docker login --username AWS --password-stdin "${ECR%%/*}"
docker build -t "$ECR:bootstrap" .          # from the application repository
docker push "$ECR:bootstrap"
```

### 5. Populate secrets

```sh
terraform output secrets_to_populate
aws secretsmanager put-secret-value --secret-id bct-dev/llm-api-key --secret-string 'REDACTED'
```

Only applies on the external-LLM path. On Bedrock there is no key.

### 6. Apply the schema

See **Database migrations** below. Do not skip to a service update.

### 7. Deploy the front end

```sh
BUCKET=$(terraform output -raw spa_bucket)
DIST=$(terraform output -raw cloudfront_distribution_id)
npm ci && npm run build
aws s3 sync dist/ "s3://$BUCKET/" --delete --exclude index.html \
  --cache-control "public,max-age=31536000,immutable"
aws s3 cp dist/index.html "s3://$BUCKET/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"
aws cloudfront create-invalidation --distribution-id "$DIST" --paths "/index.html" "/"
```

Order matters: fingerprinted assets first, then `index.html`. Reversed, a viewer
can receive a shell referencing assets that are not uploaded yet.

---

## Database migrations

**Never at container start.** With more than one task, every task races to
migrate the same schema on every deploy and every autoscale event; a failure
half-way leaves a partially migrated schema with no rollback, and rolling the
image back does not roll the schema back. ADR-010.

The pipeline is:

```
dotnet ef migrations script --idempotent   →  reviewable SQL artefact
              ↓
    scan for DROP TABLE / DROP COLUMN      →  fail the build if found
              ↓
      approval on the GitHub environment
              ↓
        apply from inside the VPC
```

`--idempotent` guards each migration with an existence check, so the script is
safe to re-run and safe against a partially migrated database.

### The in-VPC runner

The database has no route to the internet, so the apply step cannot run on a
GitHub-hosted runner. Options, in order of preference:

1. **CodeBuild project** attached to the app subnets and the ECS security group,
   invoked by the workflow. Not provisioned here — ADR-014 flags the CI platform
   as unconfirmed.
2. **A one-off ECS task** running a migration image on the same cluster.
3. **SSM port forwarding** through an instance in the VPC. Manual; acceptable
   for dev, not a pipeline.

`terraform output app_subnet_ids` and `ecs_security_group_id` give the runner
what it needs.

### Backwards compatibility

Rolling deployment means old and new code run simultaneously. Use expand/contract:

1. **Expand** — add the column as nullable, deploy code that writes both.
2. **Migrate** — backfill.
3. **Contract** — a *later* release drops the old column.

Nothing enforces this. It is a review responsibility.

---

## Rollback

| Failure | Action | Time |
|---|---|---|
| API deploy fails health checks | Automatic. The ECS circuit breaker rolls back to the previous task definition. | ~5 min, unattended |
| API is healthy but wrong | `aws ecs update-service --task-definition <previous-revision> --force-new-deployment` | ~5 min |
| Front-end release is bad | Restore the previous S3 object versions, then invalidate. Versioning is on for exactly this. | ~10 min |
| Bad migration | Restore-to-point-in-time into a **new** instance, then repoint. There is no "undo migration". | 30–90 min |
| Bad infrastructure change | `git revert`, re-plan, re-apply. Read the plan — a revert can destroy. | varies |

Front-end rollback:

```sh
aws s3api list-object-versions --bucket "$BUCKET" --prefix index.html
aws s3api copy-object --bucket "$BUCKET" --key index.html \
  --copy-source "$BUCKET/index.html?versionId=<previous>"
aws cloudfront create-invalidation --distribution-id "$DIST" --paths "/*"
```

---

## Environment differences

| Setting | dev | uat | prod |
|---|---|---|---|
| AZs | 2 | 2 | 3 |
| NAT gateways | 1 | 1 | 3 |
| Task CPU / memory | 512 / 1024 | 1024 / 2048 | 2048 / 4096 |
| Tasks min–max | 1–2 | 2–4 | 3–20 |
| RDS class | db.t3.large | db.t3.xlarge | db.r6i.xlarge |
| RDS Multi-AZ | no | no | **yes** |
| Backup retention | 7d | 14d | 35d |
| Deletion protection | no | yes | yes |
| Final snapshot | skipped | taken | taken |
| Log retention | 30d | 90d | 365d |
| WAF | count only | enforcing | enforcing |
| ECS Exec | enabled | disabled | disabled |
| CloudFront price class | 100 | 100 | All |

Production sizing is a **placeholder** pending real load data (U14).

---

## Cost drivers

Rough monthly order of magnitude in us-east-1, excluding data transfer.

| Item | dev | prod | Note |
|---|---|---|---|
| **RDS SQL Server SE** | ~$300 | ~$1,400 | **The dominant cost.** `license-included` bills per vCPU. Multi-AZ doubles it. Evaluate Web or Express edition for dev. |
| VPC interface endpoints | ~$100 | ~$160 | ~$7/endpoint/AZ. 7–8 endpoints × 2–3 AZs adds up quietly. |
| NAT gateways | ~$33 | ~$100 | Per-AZ in prod, plus per-GB processing. |
| ECS Fargate | ~$20 | ~$260 | Scales with task count. |
| ALB | ~$20 | ~$25 | Plus LCU. |
| CloudFront, WAF, S3, logs, KMS | ~$30 | ~$120 | WAF is ~$5/ACL + $1/rule + per-request. |
| **If enabled:** OpenSearch | — | ~$200+ | Two r-class nodes. |
| **If enabled:** ElastiCache | — | ~$50+ | Two t4g.small. |

The two levers that matter: **RDS edition/sizing**, and **the number of
interface endpoints**. Dropping endpoints pushes traffic through NAT — cheaper
in fixed cost, more expensive per GB, and it puts data-plane traffic on the
public path.
