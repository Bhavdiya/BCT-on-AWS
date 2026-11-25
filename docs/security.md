# Security

Controls implemented in `terraform/`, followed by controls that belong at the
account level and are deliberately out of this stack's scope.

Classification: **REQUIRED** — implemented here · **RECOMMENDED** — should exist
before production traffic, not created by this stack · **OPTIONAL** — judgement
call on cost and value.

---

## Verified properties

These were checked against the configuration after the plan run. Each is
reproducible with the command shown.

| # | Property | Result | How to re-check |
|---|---|---|---|
| 1 | Database not publicly accessible | `publicly_accessible = false`, and the data-tier route table has no default route at all | `grep -rn publicly_accessible terraform/modules/` |
| 2 | No security group admits `0.0.0.0/0` on ingress | Only one `0.0.0.0/0` exists in the whole stack, an **egress** rule on 443 | `grep -rn "0.0.0.0/0" terraform/modules/*/main.tf` |
| 3 | No database port open to the internet | `rds-sg` has exactly one ingress rule and it references `ecs-sg`; no CIDR rule exists on it | inspect `modules/security/main.tf` |
| 4 | No wildcard IAM resource without justification | 9 occurrences, each either a non-scopable action or a key policy — table below | `grep -rn 'resources = \["\*"\]' terraform/modules/` |
| 5 | No secret value in code, state or tfvars | No module writes a secret value; `tfvars` contain only region, owner, cost centre | `grep -rn "secret_string\|password =" terraform/modules/` |
| 6 | Provider and Terraform versions pinned | `~> 1.13` and `~> 6.0`, with committed `.terraform.lock.hcl` | `cat terraform/environments/dev/versions.tf` |

### Wildcard IAM resources, individually justified

| Location | Actions | Why `*` |
|---|---|---|
| `iam/main.tf:27` | `ecr:GetAuthorizationToken` | AWS does not support a resource restriction on this action |
| `iam/main.tf:137` | `xray:PutTraceSegments` and friends | X-Ray segment ingestion has no resource ARN |
| `iam/main.tf:154` | `ssmmessages:*Channel` | ECS Exec channel actions are not resource-scopable |
| `cicd/main.tf:125` | `ecr:GetAuthorizationToken` | as above |
| `cicd/main.tf:170` | `ecs:RegisterTaskDefinition` | a revision has no ARN before it is created |
| `cicd/main.tf:183` | `ecs:UpdateService` and friends | **constrained** by `ArnEquals ecs:cluster` to one cluster |
| `kms/main.tf:11,33,62` | key policy statements | in a key policy, `Resource: "*"` means *this key*; the service statements are further constrained by `kms:EncryptionContext` and `kms:ViaService` + `kms:CallerAccount` |

No policy grants `Action: "*"`. No policy grants a resource wildcard that is
both unscoped and avoidable.

---

## REQUIRED — implemented

### Identity and access

- **No long-lived AWS credentials anywhere.** The application uses the ECS task
  role; CI uses GitHub OIDC federation. No access key is created by this stack.
- **Execution and task roles are separate.** Collapsing them would give the
  application the agent's ECR and log permissions for no reason.
- **Secret reads are scoped to exact ARNs**, not `secretsmanager:*`.
- **`iam:PassRole` is scoped** to the two task roles and conditioned on
  `iam:PassedToService = ecs-tasks.amazonaws.com`. An unscoped PassRole on a
  deploy role is a privilege-escalation path: it lets the pipeline run a task as
  any role in the account.
- **OIDC trust is scoped on `sub`, not just `aud`.** A trust policy that checks
  only `aud = sts.amazonaws.com` is satisfied by every GitHub Actions job in
  existence. Plan is pinned to `repo:<owner>/<name>:*`; deploy is pinned to
  `repo:<owner>/<name>:environment:<env>`.
- **Permissions boundary supported** via `permissions_boundary_arn`, unset by
  default.

### Network

- Three subnet tiers; the data tier has **no route to or from the internet**.
- Every security group rule references another security group. The one exception
  is the ALB, which references CloudFront's **managed prefix list**.
- **Defence in depth at the ALB.** The prefix list is necessary but not
  sufficient — it admits all CloudFront traffic, including another AWS
  customer's distribution aimed at your ALB. The listener's default action is
  therefore a 403, and a listener rule forwards only when a shared
  `X-Origin-Verify` header matches a value known to our distribution alone.
- VPC interface endpoints keep secrets, config, registry and log traffic off the
  public path.
- VPC flow logs capture rejected traffic.

### Data protection

- Customer-managed KMS key with annual rotation; the key policy grants services
  only via `kms:ViaService` within this account.
- RDS: encrypted storage, encrypted Performance Insights, encrypted
  RDS-managed master secret, `rds.force_ssl = 1` so the engine refuses
  non-TLS clients.
- S3: public access blocked, versioned, `BucketOwnerEnforced` ownership, and a
  bucket policy denying any request with `aws:SecureTransport = false`.
- Secrets Manager holds containers only — **Terraform never writes a value**,
  because a value passed through Terraform is written to state in plaintext.

### Edge

- WAFv2 with four AWS managed rule groups and a per-IP rate limit.
- `count_only = true` in dev for an initial soak. Enforcing an unfamiliar rule
  set on day one is the usual reason a WAF gets switched off permanently after
  it blocks legitimate traffic; uat and prod enforce.
- CloudFront `Managed-SecurityHeadersPolicy` on both behaviours (HSTS,
  X-Content-Type-Options, frame options, referrer policy).
- API behaviour uses `Managed-CachingDisabled` — a per-user API response cached
  at the edge is a cross-user data leak.
- TLS 1.2 minimum at the edge; TLS 1.3-capable policy at the ALB.

---

## RECOMMENDED — not created by this stack

Account-level controls. They protect every stack in the account, so owning them
in one application's Terraform would be wrong — two applications would fight
over the same singleton resources.

| Control | Why | Rough cost |
|---|---|---|
| **CloudTrail** organisation trail | Without it there is no audit record of API calls. This is the single most important gap if the account does not already have one. | ~$2/mo + S3 |
| **GuardDuty** | Detects credential misuse, crypto-mining, and traffic to known-bad destinations. Uses the flow logs and CloudTrail already produced. | ~$30–80/mo at this scale |
| **AWS Config** | Detects drift from the posture above — someone opening a security group by hand. | ~$10–30/mo |
| **Security Hub** | Aggregates the above against CIS/AWS FSBP. Valuable only if someone reads it. | ~$10–40/mo |
| **IAM Access Analyzer** | Flags resource policies granting external access. | Free |
| **S3 Block Public Access at account level** | Belt and braces over the per-bucket setting. | Free |

If exactly one of these is adopted: **CloudTrail**, then **GuardDuty**.

## OPTIONAL

| Control | Trade-off |
|---|---|
| WAF logging to Kinesis Firehose | Needed for tuning false positives; adds Firehose and S3 cost. Supported by the module, unset. |
| AWS Shield Advanced | ~$3,000/mo. Only for a genuine DDoS threat model. |
| Network Firewall | Egress is already limited to 443. Only if egress filtering by FQDN is required. |
| Secrets rotation lambda | RDS credentials already rotate. Only the external LLM key would need this. |
| Inspector | Duplicates ECR scan-on-push for containers; adds value for EC2, of which there is none. |

---

## Known weaknesses

Stated plainly rather than buried.

1. **RDS SQL Server cannot use IAM database authentication.** The stack gets as
   close as the engine allows — a rotated credential in Secrets Manager reachable
   only by the task role — but it is a password, not a token. Aurora PostgreSQL
   is the only way to satisfy this literally. ADR-003.

2. **Without a domain, ALB traffic from CloudFront is HTTP.** The current
   environments configure no domain, so the listener runs on port 80. The hop is
   protected by the prefix list and the origin-verify header, but it is not
   encrypted, and it crosses AWS's network outside your VPC. **Do not run
   production this way** — set `domain_name` and `hosted_zone_id`, or supply
   `alb_certificate_arn`.

3. **The origin-verify secret lives in Terraform state.** `random_password`
   values are stored in state. State is encrypted and access-controlled, but
   anyone who can read state can read this header value. Rotating it means a
   `terraform apply` that taints the resource.

4. **The Bedrock guardrail is advisory unless the application uses it.** A
   guardrail only applies when its ID is passed on each `InvokeModel` call.
   Terraform creates it and exports the ID; enforcement is an application change.

5. **No account-level logging is assumed to exist.** If CloudTrail is not
   already on, there is no audit trail for anything here.

6. **The container contract is unverified.** Port 8080 and `/healthz` are
   assumptions (U2, U3). Wrong values do not create a security hole, but they do
   produce a service that never passes a health check.
