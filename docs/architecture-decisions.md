# Architecture Decision Records — BCT on AWS

Every ADR carries an explicit **Evidence** line. Where it reads *prerequisites
document only*, no source code was available to confirm the decision — see
[`application-discovery.md`](application-discovery.md#evidence-availability).

Status values: `Accepted` · `Accepted (provisional)` — sound on current evidence
but must be re-tested once the source code is available.

---

## ADR-001 — ECS Fargate over EKS for the API tier

**Status:** Accepted
**Evidence:** PD-alternative A2 ("Azure App Service (with deployment slots) or AKS/containers")

### Problem
The PD offers App Service or AKS. Neither has an exact AWS equivalent, and the
choice sets the operational model for the life of the service.

### Options
1. **EKS** — closest to AKS. Full Kubernetes API, cluster autoscaling, broad ecosystem.
2. **ECS Fargate** — no nodes to patch, no control plane to upgrade, IAM-native task identity.
3. **App Runner** — closest to App Service ergonomically; source-to-URL in one resource.
4. **Elastic Beanstalk** — legacy; EC2 fleet management resurfaces.

### Decision
**ECS Fargate.**

### Reason
The workload is one stateless HTTP API. Nothing in the PD calls for service
mesh, operators, CRDs, multi-tenancy or pod-level scheduling control — the things
that justify Kubernetes. EKS would add a control-plane charge, a node lifecycle,
an add-on upgrade cadence and a second RBAC system to reconcile with IAM, all to
run a single container image.

App Runner was the closest ergonomic match to App Service and was rejected on
network grounds: its VPC integration is egress-only, so placing a WAF-inspected
ALB in front of it and reaching RDS over private subnets is awkward, and it
offers no fine-grained control over the ingress path the PD requires (R16).

Fargate keeps the IAM task role as the sole workload identity, which is the exact
shape needed to replace Managed Identity (ADR-004).

### Consequences
- No node patching, no Kubernetes version treadmill.
- Deployment-slot semantics are lost. Rolling deployment plus
  `deployment_circuit_breaker` with automatic rollback covers the safety
  property slots are normally used for; true blue/green would need CodeDeploy,
  which is out of scope.
- Per-vCPU-hour cost is higher than well-packed EC2. At one to ten tasks the
  difference is far below the cost of operating a cluster.
- Portability to another Kubernetes platform is reduced. The container image
  stays portable; the orchestration definition does not.

### Assumptions
Stateless API (U9). No pod-level scheduling requirement. Team has no existing
Kubernetes platform investment that this would strand.

---

## ADR-002 — Split ingress: CloudFront for the SPA, ALB for the API

**Status:** Accepted
**Evidence:** PD-explicit R16, R20, R21; stack-inherent (Vite SPA)

### Problem
Azure collapses global and regional ingress into Front Door and Application
Gateway. AWS splits the responsibilities differently, and the SPA and API have
genuinely different serving characteristics.

### Options
1. Everything through CloudFront, SPA from S3, `/api/*` to an ALB origin.
2. Everything through the ALB, with the API serving the SPA's static files.
3. CloudFront for the SPA only; the API on its own public ALB hostname.

### Decision
**Option 1** — one CloudFront distribution, two origins: S3 (default behaviour)
and the ALB (`/api/*`), with WAF at the edge.

### Reason
A Vite bundle is immutable, fingerprinted, globally cacheable static content;
serving it from ECS burns compute on `Content-Type` headers and puts cache
behaviour behind an application deployment. Option 2 also couples front-end
releases to API releases, which the PD's separate build tooling implies are
independent.

Option 3 exposes a second public hostname and forces CORS plus a second
certificate and WAF association for no benefit. A single origin removes CORS
from the browser path entirely.

`custom_error_response` mapping 403 and 404 to `/index.html` with a 200 is what
satisfies R21 — without it every deep link is a 404 from S3.

### Consequences
- Cache invalidation becomes a release step (`create-invalidation` on `/index.html`).
- Two WAF Web ACLs are required: a `CLOUDFRONT`-scoped one (must be created in
  `us-east-1`) and optionally a `REGIONAL` one on the ALB. Only the CloudFront
  one is provisioned; the ALB is not publicly reachable except through CloudFront.
- The CloudFront certificate must be issued in `us-east-1` regardless of the
  application region. Handled by a second aliased provider.

### Assumptions
SPA is a static bundle with client-side routing (stack-inherent). API paths are
prefixed consistently — `/api/*` is assumed and is a variable (U3-adjacent).

---

## ADR-003 — RDS for SQL Server, and the Managed Identity gap

**Status:** Accepted (provisional)
**Evidence:** PD-explicit R2, R4, R5, R6

### Problem
The PD requires SQL Server and, separately, requires "access via Managed
Identity — no connection strings in code or config". On AWS these two
requirements are in direct conflict.

### Options
1. **RDS for SQL Server** — same dialect, EF Core provider unchanged, zero code change.
2. **Aurora PostgreSQL** — supports IAM database authentication, so the
   no-credential requirement is fully satisfiable; requires an EF Core provider
   swap and a data-type/migration review.
3. RDS SQL Server on EC2 — full control, full operational burden. Rejected outright.

### Decision
**RDS for SQL Server**, with the credential requirement met by
`manage_master_user_password = true`.

### Reason
This is the honest constraint: **RDS for SQL Server does not support IAM
database authentication.** That feature covers MySQL, MariaDB and PostgreSQL
only. There is no configuration that makes SQL Server on RDS accept an IAM
token.

The closest achievable posture is: RDS generates the master password, stores it
in Secrets Manager under a CMK, and rotates it on a managed schedule; the ECS
task role is granted `secretsmanager:GetSecretValue` on exactly that secret ARN.
The application assembles its connection string at runtime from a secret it
fetched using its workload identity.

That satisfies the *spirit* of R4 — nothing is in code, config, an image or an
environment variable — but it is a rotated credential, not a token. The
difference is real and is recorded here rather than glossed over.

Aurora PostgreSQL would satisfy R4 literally. It was not chosen because the PD
names SQL Server explicitly (R2) and EF Core migrations already exist (R3);
changing the provider is an application decision with a migration cost, not an
infrastructure one. It remains the correct answer if passwordless auth is a hard
compliance requirement.

### Consequences
- A rotating credential exists and must be protected; the task role's read is
  scoped to one secret ARN, and the KMS key policy is the second control.
- `license-included` on SE carries a per-vCPU licence cost that dominates the
  database bill. Dev uses `db.t3.large`; production sizing is a placeholder (U14).
- Multi-AZ in production gives a synchronous standby and automatic failover.
  Cross-Region DR requires read replicas or snapshot copy — see
  `disaster-recovery.md`.

### Assumptions
SQL Server dialect is genuinely required, not incidental (U13). EF Core provider
is `Microsoft.EntityFrameworkCore.SqlServer`.

---

## ADR-004 — IAM task role as the Managed Identity replacement

**Status:** Accepted
**Evidence:** PD-explicit R9

### Problem
Managed Identity gives an Azure workload a credential-free identity. The AWS
equivalent must cover the same service-to-service calls with no stored keys.

### Options
1. IAM role assumed by the ECS task (`ecs-tasks.amazonaws.com` trust).
2. IAM user with long-lived access keys injected as environment variables.
3. IRSA — requires EKS, excluded by ADR-001.

### Decision
**ECS task role**, distinct from the task *execution* role.

### Reason
Fargate delivers rotating credentials to the container through the task metadata
endpoint; the SDK picks them up with no configuration. Option 2 is what the PD
explicitly forbids.

The two-role split matters and is frequently collapsed by mistake:
- **Execution role** — used by the ECS agent, not the application. Pulls the ECR
  image, writes the log stream, resolves `secrets` in the task definition.
- **Task role** — assumed by the application. Reads Secrets Manager at runtime,
  calls Bedrock, writes X-Ray segments.

Collapsing them would grant the application the agent's ECR and log-group
permissions for no reason.

### Consequences
- No key material anywhere in the pipeline or the image.
- Every new AWS dependency needs a task-role policy statement; there is no
  ambient permission to fall back on.
- Local development cannot use the task role and needs a separate profile.

### Assumptions
All AWS access is from inside the task. No sidecar needs a separate identity (U9).

---

## ADR-005 — Retain Microsoft Entra ID; do not introduce Cognito

**Status:** Accepted
**Evidence:** PD-explicit R7, R8

### Problem
The brief asks explicitly whether Entra should remain the identity provider with
AWS integration, or be federated behind Cognito.

### Options
- **A — Entra direct.** The SPA runs the OIDC code flow against Entra; the API
  validates Entra-issued JWTs.
- **B — Entra federated into a Cognito user pool.** Cognito becomes the token
  issuer; Entra becomes an upstream IdP.

### Decision
**Option A. Entra ID remains the direct issuer. No Cognito user pool is created.**

### Reason
The PD describes an application that *already* validates Entra tokens: "app
registrations for OIDC sign-in (web) and JWT validation (API), and Entra group →
role mapping". Choosing B would mean:

- changing the API's JWT authority, audience and issuer configuration — an
  application code change, to gain nothing;
- re-mapping six Entra groups into Cognito groups and keeping that mapping in
  sync forever, a second source of truth for authorization;
- a token-translation hop that adds a failure domain and latency to every
  sign-in;
- paying Cognito MAU charges for users who already have Entra licences.

Cognito earns its place when the application needs an identity store AWS can own
— B2C sign-up, SAML-to-OIDC bridging for an app that only speaks one, or AWS
credential vending via an identity pool. **None of those apply here.** Nothing in
the architecture requires the browser to hold AWS credentials; all AWS access is
server-side through the task role (ADR-004).

This directly answers the brief's instruction not to replace Entra
unnecessarily. Introducing Cognito would be exactly the one-to-one Azure→AWS
reflex the brief warns against.

### Consequences
- No AWS-side identity resource. Tenant ID, client ID and audience are Terraform
  variables with no defaults, so a deploy fails fast rather than silently
  misconfiguring auth (U11).
- The API needs egress to `login.microsoftonline.com` to fetch signing keys —
  satisfied by the NAT gateway; no VPC endpoint exists for a third-party IdP.
- Entra availability is a hard dependency of the sign-in path. It already was.
- If AWS-native credential vending is ever needed, a Cognito **identity** pool
  can be added without disturbing the user-facing flow.

### Assumptions
The Entra tenant exists with the app registrations described (U11). Group→role
mapping is enforced in application authorization policies, not infrastructure (U12).

---

## ADR-006 — NAT gateway *and* VPC endpoints, not one or the other

**Status:** Accepted
**Evidence:** PD-explicit R12, R17

### Problem
Private tasks need to reach AWS service APIs and at least one third-party
endpoint. NAT and PrivateLink solve overlapping but distinct parts of that.

### Options
1. NAT only — simple, all traffic egresses to the internet, per-GB charges.
2. VPC endpoints only — no internet path at all.
3. Both.

### Decision
**Both.** Interface endpoints for the AWS services on the hot path, plus a NAT
gateway for third-party egress. One NAT in dev/uat, one per AZ in production.

### Reason
Option 2 is impossible here: R12 requires outbound HTTPS to an LLM provider and
ADR-005 requires reaching Entra's OIDC metadata. Neither is an AWS service, so
neither has a PrivateLink endpoint.

Option 1 alone would push Secrets Manager, ECR, CloudWatch Logs and SSM traffic
through the NAT and out to the public internet, which contradicts R17's "private
data-plane connectivity" and adds NAT processing charges to every image pull and
every log flush.

The endpoint set is chosen from what the architecture actually calls:
`secretsmanager`, `ssm`, `ecr.api`, `ecr.dkr`, `logs`, `appconfig`,
`appconfigdata`, `bedrock-runtime`, plus an S3 **gateway** endpoint (free, and
required for ECR layer pulls, which fetch from S3).

### Consequences
- Interface endpoints cost roughly $7/month each per AZ, before data. At nine
  endpoints across two AZs this is a real line item and is called out in
  `deployment.md` as a cost driver.
- Single NAT in dev/uat is a deliberate single point of failure for private
  egress, accepted for cost. Production runs one per AZ.
- Endpoint security group allows 443 from the VPC CIDR only.

### Assumptions
The LLM provider and Entra are the only third-party egress destinations (U7).

---

## ADR-007 — CloudWatch as the telemetry backend; X-Ray behind a flag

**Status:** Accepted
**Evidence:** PD-explicit R19

### Problem
Application Insights bundles logs, metrics, distributed tracing and APM. AWS
splits these across CloudWatch Logs, CloudWatch Metrics and X-Ray.

### Options
1. CloudWatch Logs + Metrics + alarms only.
2. Add X-Ray tracing.
3. Managed Prometheus + Grafana.
4. A third-party APM.

### Decision
**Option 1 as the baseline, with X-Ray available behind `enable_xray` (default
off).**

### Reason
Logs, metrics, alarms and Container Insights cover the operational floor with no
application change. X-Ray is genuinely useful but is **not free of code
changes** — it needs the `AWSXRayRecorder` SDK wired into the ASP.NET Core
pipeline and a sidecar daemon in the task definition. Enabling it by default
would provision a sidecar for instrumentation that may not exist (U7, U9).

Managed Prometheus is over-scaled for one service. A third-party APM is a
procurement decision, not an architecture one.

### Consequences
- Distributed tracing is off until the application is instrumented; the flag
  and the sidecar wiring are ready.
- Log retention is configurable per environment (30d dev, 90d uat, 365d prod).
- Alarms cover ECS CPU/memory, ALB 5xx and target health, and RDS CPU/storage/
  connections, delivered to an SNS topic whose subscribers are a variable.

### Assumptions
Structured logging to stdout (the ASP.NET Core default) — required for the
`awslogs` driver to be useful.

---

## ADR-008 — Bedrock as the default LLM path, external provider supported

**Status:** Accepted (provisional)
**Evidence:** PD-alternative A1; PD-explicit R10, R11, R12

### Problem
The PD names "Azure OpenAI (endpoint + model deployment) **or** Anthropic
Claude". Which one BCT actually calls is a property of the code (U7). The two
have materially different AWS infrastructure.

### Options
1. Bedrock only — AWS-native, IAM-authorised, private via `bedrock-runtime` endpoint.
2. External Anthropic API only — API key in Secrets Manager, egress on 443.
3. Both, selectable.

### Decision
**Option 3**, defaulting to Bedrock. `enable_bedrock` provisions a guardrail and
a least-privilege invoke policy; `llm_provider = "external"` instead provisions
a Secrets Manager entry for the provider key. Egress on 443 exists either way.

### Reason
Committing to one path without knowing which SDK the code uses would guarantee
being wrong half the time. Both paths are cheap to express and mutually
exclusive at plan time.

Bedrock is the better default: it removes a third-party credential entirely
(IAM replaces the API key, satisfying R4's spirit), keeps traffic on
PrivateLink, and gives a guardrail as an enforcement point. If the code calls
`api.anthropic.com` directly, flipping the variable is the whole change.

### Consequences
- **Bedrock model access cannot be enabled by Terraform.** It is a one-time
  per-account console action. Documented as a manual prerequisite.
- Most regions, including `us-east-1` for newer Anthropic models, require a
  **cross-region inference profile** ARN rather than the bare foundation-model
  ARN. The invoke policy grants both shapes.
- A guardrail is created but is only enforced if the application passes the
  guardrail ID on each `InvokeModel` call — an application change, flagged in
  `deployment.md`.
- The external path leaves an API key in Secrets Manager, with rotation the
  provider's problem.

### Assumptions
If Bedrock is used, Anthropic Claude models are the target (PD names Claude).

---

## ADR-009 — AppConfig for settings and feature flags

**Status:** Accepted
**Evidence:** PD-explicit R15

### Problem
R15 requires a settings and feature-flag store equivalent to Azure App
Configuration.

### Options
1. AWS AppConfig.
2. SSM Parameter Store.
3. Plain ECS environment variables.

### Decision
**AppConfig**, with the `AWS.AppConfig.FeatureFlags` profile type.

### Reason
Option 3 fails the requirement outright — changing a flag would mean a new task
definition and a deployment, which is the opposite of a feature flag. Parameter
Store handles settings but has no flag semantics, no validation, no staged
rollout and no automatic rollback.

AppConfig is the only one of the three with the deployment-strategy and bake-time
model that makes a flag flip safely reversible, which is the actual point of the
requirement.

### Consequences
- Reading flags requires the AppConfig Agent sidecar or the SDK — an application
  change (U7). The infrastructure is provisioned and ready either way.
- Flag *content* is deliberately not managed in Terraform; a hosted configuration
  version in state would fight with runtime flag changes. Terraform owns the
  application, environment, profile and strategy only.

### Assumptions
Flags are a genuine requirement, not aspirational language in the PD.

---

## ADR-010 — EF Core migrations as a gated CI step, never at container start

**Status:** Accepted
**Evidence:** PD-explicit R3

### Problem
R3 requires migrations applied at release. The mechanism determines whether a
routine deploy can corrupt the database.

### Options
1. `Database.Migrate()` at application startup.
2. A separate one-off ECS task run before the service update.
3. A gated CI job using `dotnet ef database update`, with a generated SQL script
   reviewed for production.

### Decision
**Option 3**, with production requiring an idempotent script and a human approval
gate.

### Reason
Option 1 is the dangerous one and it is common. With `desired_count > 1` every
task races to migrate the same schema on every deploy and on every autoscale
event; a migration that fails halfway leaves a partially-migrated schema with no
rollback and the service crash-looping. It also means a rollback of the image
does not roll back the schema.

Option 2 is a real improvement but still applies whatever the code contains,
unreviewed.

Option 3 makes the schema change a reviewable artefact.
`dotnet ef migrations script --idempotent` produces SQL a DBA can read before it
touches production. The brief's "do not automatically execute destructive
migrations" is only satisfiable if a human can see the SQL first.

### Consequences
- One extra pipeline stage and one approval.
- The migration runner needs network access to a private RDS instance — a
  CodeBuild project in the VPC, or a bastion-free SSM session. Documented, not
  provisioned, because the CI platform is not confirmed.
- Backwards-incompatible migrations still need the expand/contract pattern; no
  tooling enforces this.

### Assumptions
Migrations are EF Core code-first (R3). A DBA or reviewer exists for production.

---

## ADR-011 — Optional services implemented but disabled

**Status:** Accepted (provisional)
**Evidence:** PD-conditional O1–O3

### Problem
The PD qualifies Service Bus, Redis and AI Search with "where the corresponding
capabilities are enabled". Whether BCT enables them is a code property (U4–U6),
and the code is unavailable.

### Options
1. Provision all three — guarantees the app has what it might need.
2. Provision none, add later — smallest footprint.
3. Implement all three as complete modules, disabled by default.

### Decision
**Option 3.** `enable_redis`, `enable_messaging` and `enable_search` all default
to `false`. Nothing is created until one is deliberately turned on.

### Reason
Option 1 violates the brief directly — an ElastiCache replication group and an
OpenSearch domain that nothing connects to are pure cost and pure attack
surface. At production sizing those two alone are several hundred dollars a
month for zero traffic.

Option 2 is honest but means a module-authoring delay at the exact moment the
capability turns out to be needed.

Option 3 costs nothing when off (`count = 0` produces no resources in the plan),
and turning one on is a one-line change reviewed like any other.

### Consequences
- The dev plan contains no Redis, no queue and no search domain. This is correct
  and expected, not an omission.
- Each module carries its own security group and subnet group, so enabling one
  is self-contained.
- If the code turns out to need them, the wiring — task-role policy, security
  group rule, connection setting — must be reviewed at that point.

### Assumptions
Absence of PD-explicit language means genuinely optional, not an oversight.

---

## ADR-012 — Multi-AZ everywhere in production; single-AZ economies in dev

**Status:** Accepted
**Evidence:** brief-explicit ("Production must support at least two Availability Zones")

### Problem
Availability and cost pull in opposite directions, and dev does not need
production's guarantees.

### Decision

| Component | dev | uat | prod |
|---|---|---|---|
| AZs | 2 | 2 | 3 |
| NAT gateways | 1 | 1 | 3 (one per AZ) |
| ECS min/max tasks | 1 / 2 | 2 / 4 | 3 / 20 |
| RDS Multi-AZ | no | no | **yes** |
| RDS deletion protection | no | yes | **yes** |
| Backup retention | 7d | 14d | 35d |
| Log retention | 30d | 90d | 365d |

### Reason
Subnets span two AZs even in dev, because a single-AZ VPC that later needs a
second AZ requires re-CIDRing — cheap to get right at creation, expensive to
retrofit. Everything else scales with the environment.

Production takes three AZs because RDS Multi-AZ failover plus ECS spread across
three zones survives a zone loss with capacity to spare; two AZs means losing
half the fleet.

Deletion protection off in dev is deliberate — dev must be destroyable. That is
also why `prevent_destroy` is not used on environment resources.

### Consequences
- Production NAT cost is ~3x dev. Justified: a single NAT is a single point of
  failure for all private egress, which includes the LLM path.
- Dev is explicitly not a fidelity test of production failover behaviour.

### Assumptions
`us-east-1` has ≥3 usable AZs (it does). Production sizing is a placeholder
pending real load data (U14).

---

## ADR-013 — S3 remote state with native lockfile locking

**Status:** Accepted
**Evidence:** brief-explicit ("Prefer S3 backend + state versioning + appropriate state locking mechanism according to the Terraform/AWS versions being used")

### Problem
State must be shared, versioned and locked. The brief asks for the locking
mechanism appropriate to the versions in use.

### Options
1. S3 + DynamoDB table lock — the long-standing pattern.
2. S3 with `use_lockfile = true` — native S3 conditional-write locking.
3. Terraform Cloud / HCP.

### Decision
**Option 2.** S3 backend, versioning on, SSE-KMS, `use_lockfile = true`, no
DynamoDB table.

### Reason
S3 native locking (Terraform 1.10+, generally available in 1.11) uses S3
conditional writes and removes the DynamoDB table entirely. The local toolchain
is **Terraform 1.15.8**, well past that threshold, so the DynamoDB table is
legacy weight: another resource, another IAM policy, another thing to
provision before the first `init`.

This is precisely the "according to the Terraform/AWS versions being used"
qualifier in the brief.

### Consequences
- Requires Terraform ≥1.10 for every operator and CI runner. Enforced by
  `required_version = "~> 1.13"`.
- The state bucket is a bootstrap dependency and cannot be created by the stack
  that stores state in it. A separate `bootstrap/` configuration with a local
  backend creates it; documented in `terraform/README.md`.
- State bucket versioning is the last line of defence against a corrupt state
  write, so it is non-negotiable and the bucket has `prevent_destroy`.

### Assumptions
CI runners are on Terraform ≥1.10.

---

## ADR-014 — GitHub Actions OIDC, no long-lived AWS keys

**Status:** Accepted (provisional)
**Evidence:** brief-explicit; CI platform not confirmed (repository empty)

### Problem
The pipeline needs AWS credentials. Stored access keys are the default failure
mode.

### Options
1. Repository secrets holding an access key pair.
2. GitHub OIDC provider federated to an IAM role.

### Decision
**Option 2.** An IAM OIDC provider for `token.actions.githubusercontent.com`
plus two roles: a read/plan role and an apply role, with trust conditions
scoped to a specific repository and — for apply — a specific environment.

### Reason
Option 1 creates a credential that never expires, lives in a system outside AWS,
and survives the departure of whoever created it. OIDC issues a short-lived
token per job.

The trust policy condition is the security control, and it must be on `sub`, not
just `aud`. A policy that trusts `repo:*` trusts every repository on GitHub.
The `sub` is pinned to `repo:<org>/<repo>:*` for plan and
`repo:<org>/<repo>:environment:<env>` for apply, so an apply cannot be triggered
from an arbitrary branch.

### Consequences
- The GitHub org/repo must be supplied as a variable; the module is not
  provisioned when it is unset, so an unconfigured deploy cannot create a
  wildcard trust.
- If CI is GitLab rather than GitHub — plausible, since the reference module
  library is on GitLab — the same pattern applies with GitLab's issuer, and the
  module needs its issuer and `sub` format changed.
- The plan role still reads state and can read secret *metadata*; it is not
  harmless and is scoped accordingly.

### Assumptions
GitHub Actions is the CI platform. **Unverified** — the repository is empty, so
no workflow files were observable.

---

## ADR-015 — No resource tagging

**Status:** Accepted
**Evidence:** requester instruction, superseding the brief's Phase 17 tagging requirement

### Problem
The original brief required a consistent tag set (`Project`, `Application`,
`Environment`, `ManagedBy`, plus configurable `Owner` and `CostCenter`). That
was implemented via the provider's `default_tags`. The requester subsequently
asked for all tags to be removed, `Name` included.

### Options
1. Remove only `ManagedBy = "Terraform"` — the narrowest reading.
2. Remove the governance tags but keep `Name`, which is what identifies a
   resource in the console.
3. Remove every tag, `Name` included.

### Decision
**Option 3**, confirmed with the requester before implementing. No resource in
`terraform/` carries a tag: no `default_tags` block, no `common_tags` locals, no
per-resource `Name`, and the `owner` and `cost_center` variables are gone.

`propagate_tags = "SERVICE"` on the ECS service and `copy_tags_to_snapshot` on
the RDS instance were also removed — both are tag machinery with nothing left to
act on.

### Reason
Explicitly requested. The choice between the three readings was material, so it
was confirmed rather than assumed.

### Consequences
These are real and are recorded so the decision can be revisited deliberately:

- **Cost allocation is not possible.** Cost Explorer can break spend down by
  service and account, but not by project, environment or owner. For a stack
  whose largest line item is a licence-included SQL Server instance, that is the
  most expensive consequence.
- **Console legibility drops.** Subnets, route tables, NAT gateways and VPC
  endpoints are identified in the console by their `Name` tag. They now display
  blank and must be distinguished by ID. Security groups, the load balancer, the
  cluster, the service and the database keep their `name` attributes and remain
  readable.
- **Tag-based automation will not match these resources**: backup plans, AWS
  Config rules, SCP conditions or Lambda schedules keyed on `Environment` or
  `Project` select nothing here.
- **Reversal is cheap and localised.** Re-adding a `default_tags` block to
  `environments/*/providers.tf` restores governance tagging for every resource
  in one place, because no module ever threaded tags through its variables.
  Restoring `Name` tags is the more tedious half — roughly 19 arguments across
  the networking and security modules.

### Assumptions
Tagging is governed elsewhere, or is genuinely not wanted. Resource naming
through `name_prefix` is considered sufficient for identification.

---

## ADR-016 — Identifying values shipped as placeholders

**Status:** Accepted
**Evidence:** requester instruction

### Problem
The configuration carried concrete organisational values — project name `bct`,
region `us-east-1`, owner `platform-engineering`, database user `bctadmin`, a
state bucket name. The requester asked for these to become placeholders.

### Options
1. Inline `<PLACEHOLDER>` tokens throughout the HCL.
2. Variables with no default, placeholdered in `terraform.tfvars`.
3. Placeholder everything including CIDRs and instance sizing.

### Decision
**Option 2**, scoped to identifying values only. Sizing, CIDRs, retention
periods and instance classes keep working defaults.

### Reason
Option 1 produces invalid HCL wherever the value is not a free-form string.
Option 3 was declined by the requester: it would leave nothing runnable and
`terraform validate` would stop being a meaningful check.

Option 2 keeps the configuration valid HCL that passes `validate` offline, while
guaranteeing a wrong value cannot reach AWS: `project` is validated against
`^[a-z][a-z0-9-]{1,21}$`, so the literal `<PROJECT_NAME>` is rejected at plan
time with a clear error. Failing loudly beats deploying a stack named
`<PROJECT_NAME>-dev`.

### Consequences
- `terraform plan` cannot run on a fresh checkout until the placeholders are
  replaced. That is the point.
- `region` no longer has a default anywhere, including `bootstrap/`.
- The backend block no longer hardcodes a region; it moves to `backend.hcl`
  alongside the bucket, so the same code works in any region.
- The us-east-1 provider alias **keeps** its literal region. CloudFront viewer
  certificates and `CLOUDFRONT`-scoped Web ACLs can only exist there; that is a
  service constraint, not a deployment choice.
- CI workflows read `vars.AWS_REGION` and `vars.PROJECT_NAME` from GitHub
  repository variables instead of literals.

### Assumptions
The stack is being handed over or templated, rather than deployed as-is by
whoever wrote it.
