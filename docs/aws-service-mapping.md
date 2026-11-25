# Azure to AWS service mapping

Each row records the candidate mapping from the brief, what was actually chosen,
and — where they differ or where the mapping is not clean — why.

**Every mapping is a decision, not a translation.** Four rows below reject the
candidate outright, and three others accept it with a caveat that changes how
the application must behave.

Evidence codes match [`application-discovery.md`](application-discovery.md):
R = required, O = optional, A = alternative, U = unknown.

---

## Accepted as proposed

| Azure | Candidate | Chosen | Evidence | Note |
|---|---|---|---|---|
| App Service / AKS | ECS Fargate | **ECS Fargate** | R13, A2 | ADR-001 |
| Application Gateway | ALB | **ALB** | R16 | Not internet-reachable; only CloudFront may connect |
| Front Door | CloudFront | **CloudFront** | R16 | Two origins, one distribution — ADR-002 |
| Azure WAF | AWS WAF | **WAFv2 Web ACL** | R16 | `CLOUDFRONT` scope, so it must be created in us-east-1 |
| VNet | VPC | **VPC** | R17 | Three subnet tiers, ADR-006 |
| Private Endpoint | PrivateLink | **VPC endpoints** | R17 | Seven interface endpoints plus an S3 gateway endpoint |
| Key Vault (secrets) | Secrets Manager + KMS | **Secrets Manager + KMS** | R11, R14 | Terraform creates the container, never the value |
| App Configuration | AWS AppConfig | **AppConfig** | R15 | ADR-009 |
| Container Registry | ECR | **ECR** | — | Immutable tags, scan on push, CMK |
| Azure certificates | ACM | **ACM** | R18 | Two certificates: regional for the ALB, us-east-1 for CloudFront |
| Managed Identity | IAM roles | **IAM task role** | R9 | ADR-004; see the SQL Server caveat below |
| Application Insights | CloudWatch / X-Ray | **CloudWatch**, X-Ray optional | R19 | ADR-007 |

## Accepted with a caveat that affects the application

| Azure | Chosen | The caveat |
|---|---|---|
| **Azure SQL Database** | RDS for SQL Server | **RDS for SQL Server has no IAM database authentication.** It exists for MySQL, MariaDB and PostgreSQL only. The PD requirement "access via Managed Identity — no connection strings in code or config" (R4) therefore cannot be met literally. What is implemented: RDS generates and rotates the master password into Secrets Manager under a CMK, and the task role may read exactly that one secret. Nothing is in code, config, the image or an environment variable — but it is a credential, not a token. Aurora PostgreSQL would satisfy R4 literally at the cost of an EF Core provider change. ADR-003. |
| **Azure OpenAI** | Bedrock, or egress to an external provider | Which the code calls is unknown (U7), so both paths exist and are selected by `llm_provider`. Bedrock is the default because it replaces the API key with IAM. Two manual prerequisites: model access must be enabled once per account in the console, and most regions require a **cross-region inference profile** ARN rather than the bare foundation-model ARN. ADR-008. |
| **Azure Blob Storage** | S3 — for the SPA bundle only | The PD names Blob Storage only in passing. No evidence exists that the application stores user files (U8), so **no object store for application data is provisioned**. The only bucket for application content holds the compiled front end. |

## Rejected — the candidate mapping was not taken

| Azure | Candidate | Decision | Why |
|---|---|---|---|
| **Microsoft Entra ID** | Cognito | **Rejected. Entra stays the issuer.** | The brief asks explicitly whether Entra should remain. It should. The PD describes an application that already validates Entra JWTs; putting Cognito in front would change the API's authority and audience, duplicate six group mappings into a second authorization source of truth, add a token-translation hop, and charge MAU for users who already hold Entra licences. Cognito earns its place when AWS must own an identity store or vend AWS credentials to the browser — neither applies, because all AWS access is server-side through the task role. **No Cognito resource is created.** ADR-005. |
| **Azure Service Bus** | SQS / SNS / EventBridge | **Implemented, disabled** | PD-conditional (O1). No evidence the application publishes or consumes messages (U5). Provisioning a queue nothing writes to is cost and attack surface for nothing. `enable_messaging = false`. ADR-011. |
| **Azure Cache for Redis** | ElastiCache | **Implemented, disabled** | PD-conditional (O2), no evidence of use (U4). `enable_redis = false`. Note the module targets **Valkey**, not Redis OSS: it is wire-compatible, actively maintained, and materially cheaper on ElastiCache. |
| **Azure AI Search** | OpenSearch | **Implemented, disabled** | PD-conditional (O3), no evidence of use (U6). An idle production-sized OpenSearch domain is one of the more expensive ways to provision nothing. `enable_search = false`. ADR-011. |

## Where AWS has no equivalent

| Azure capability | Status |
|---|---|
| **Resource Group** as a lifecycle boundary | No equivalent. AWS Resource Groups are a saved tag query; deleting one deletes nothing. Containment comes from the account boundary and from the `<project>-<environment>` name prefix. Tagging was removed from this stack by request, so no tag-based grouping is available either. No resource-group object is created. |
| **App Service deployment slots** | No equivalent. Rolling deployment with `deployment_circuit_breaker` and automatic rollback covers the safety property slots normally provide. True blue/green needs CodeDeploy, which is out of scope. |
| **Geo-redundant backup**, as Azure means it | RDS automated backups are regional. Cross-Region durability requires explicit snapshot copy or a cross-Region read replica. Not provisioned; the options and their RPO/RTO are in `disaster-recovery.md`. |
| **Directory / HR hierarchy sync** | No mechanism, schedule or source system is described in the PD (U12), so nothing is provisioned. Flagged rather than invented. |

## Mappings the brief listed that are not used

| Candidate | Why not |
|---|---|
| SNS / EventBridge for messaging | SQS alone covers the described async/eventing need. Adding a topic or bus before there is a fan-out or routing requirement is speculative. |
| X-Ray as a baseline | Requires SDK instrumentation in the application plus a sidecar. Wired and available behind `enable_xray`, off by default. ADR-007. |
| DynamoDB for state locking | Superseded. Terraform 1.10+ locks S3 state with conditional writes (`use_lockfile`); the toolchain here is 1.15.8. ADR-013. |
