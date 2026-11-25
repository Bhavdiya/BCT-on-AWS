# BCT — Application Discovery

**Date:** 2026-09-05
**Analyst:** Infrastructure discovery pass, preceding AWS Terraform implementation
**Status:** BLOCKED on primary evidence source — see [Evidence availability](#evidence-availability)

---

## Evidence availability

This document was supposed to derive every infrastructure requirement from the
application source code. **The source code was not obtainable.** What follows is
the exact verification trail, so that every downstream claim can be audited
against what was actually checked.

### Repository supplied by the requester

`<APPLICATION_REPO_URL>` — referred to below as `<APPLICATION_REPO>`.

```
$ git clone <APPLICATION_REPO_URL> bct
Cloning into 'bct'...
warning: You appear to have cloned an empty repository.

$ ls -la bct
total 0
drwxr-xr-x@ 3  .
drwx------@ 4  ..
drwxr-xr-x@ 9  .git          <- nothing but the git directory
```

The repository was confirmed to *exist but contain no commits*, rather than to be
missing or permission-denied. Controls were run to distinguish the two cases:

| Remote | `git ls-remote` output | Interpretation |
|---|---|---|
| `<CONTROL_MISSING_REPO>` | `remote: Repository not found.` | control: a missing repo produces an explicit error |
| `<CONTROL_POPULATED_REPO>` | `<sha> HEAD` / `<sha> refs/heads/master` | control: a populated repo advertises refs |
| **`<APPLICATION_REPO>`** | **(no output, clean exit, zero refs)** | **repository is initialised and empty** |

An empty ref advertisement with no error is GitHub's signature for a real
repository with zero commits.

`<CONTROL_MISSING_REPO>` is a deliberately non-existent path and
`<CONTROL_POPULATED_REPO>` an unrelated repository known to have commits; both
were probed under the same credentials to establish what each outcome looks
like.

### Prior search of the local environment

Before the repository was supplied, the workstation was searched exhaustively:

| Search | Command basis | Result |
|---|---|---|
| .NET solution/project files | `find ~ -name '*.sln' -o -name '*.csproj'` | 0 results |
| ASP.NET Core entrypoints | `find ~ -name 'Program.cs' -o -name 'appsettings*.json'` | 0 results |
| Project by name | `find ~ -iname '*<PROJECT_NAME>*' -o -iname '*business*case*'` | 0 results |
| Frontend by dependency | `grep -rl '"@mui/material"' ~/Documents --include=package.json` | 0 results |
| Local git remotes | scan of every `.git` dir, filtered on the project and organisation names | 0 results |
| GitLab `<GITLAB_GROUP>` group | project + group API, public project search | group private; no `bct` project visible |

### Consequence

No file in the following categories was available for inspection — every one of
them was named in the discovery brief:

`*.sln` · `*.csproj` · `package.json` · `appsettings*.json` · `Dockerfile` ·
`docker-compose*.yml` · `.github/workflows/*` · EF Core migrations ·
`Program.cs` / `Startup.cs` · authentication and authorization configuration ·
existing Terraform / Bicep / ARM / Kubernetes / Helm manifests

Consequently **not one requirement below is supported by code evidence.** Every
requirement is instead traced to the *prerequisites document* (PD) — the written
"Production Deployment Prerequisites" statement supplied with the engagement —
or to a property of the declared technology stack that holds independently of
this particular codebase (marked *stack-inherent*).

The distinction is preserved in every table. **Nothing in this document should be
read as a finding about the BCT codebase.**

---

## Declared application components

Source: PD. Unverified against code.

| Component | Declared technology | Runtime consequence |
|---|---|---|
| API | ASP.NET Core 8, C#, REST | Long-running HTTP server process; needs the ASP.NET Core 8 runtime |
| Data access | Entity Framework Core | Relational store; schema versioned by EF Core migrations |
| Front end | React 18 + TypeScript + Vite + MUI | Compiles to static assets; no server-side runtime |
| Build (API) | .NET 8 SDK | CI-agent-only dependency |
| Build (SPA) | Node.js 18+ LTS | CI-agent-only dependency; explicitly "not required at runtime" per PD |

**Stack-inherent conclusion:** a Vite SPA emits a static bundle with client-side
routing. That combination determines the front-end hosting shape (object store +
CDN with a rewrite-to-index fallback) regardless of what the application does,
which is the one front-end decision that can be made safely without the code.

---

## Requirement classification

Legend for **Evidence**:
- **PD-explicit** — stated as required in the prerequisites document
- **PD-conditional** — stated in the PD with qualifying language ("where the corresponding capabilities are enabled")
- **PD-alternative** — the PD names two or more mutually exclusive options
- **Stack-inherent** — follows from the declared technology regardless of codebase
- **No evidence** — neither the PD nor the stack establishes it

### REQUIRED

| # | Requirement | Evidence | PD wording / basis |
|---|---|---|---|
| R1 | ASP.NET Core 8 runtime on the hosting tier | PD-explicit | "ASP.NET Core 8 runtime on the hosting tier" |
| R2 | Relational database, SQL Server dialect | PD-explicit | "Azure SQL Database (or SQL Server 2019+), sized per environment" |
| R3 | EF Core migrations applied at release | PD-explicit | "with EF Core migrations applied at release" |
| R4 | No connection strings in code or config | PD-explicit | "Access via Managed Identity — no connection strings in code or config" |
| R5 | TLS enforced on the data connection | PD-explicit | "TLS enforced" |
| R6 | Automated backups | PD-explicit | "automated backups/geo-redundancy per your data policy" |
| R7 | OIDC sign-in (web) and JWT validation (API) | PD-explicit | "app registrations for OIDC sign-in (web) and JWT validation (API)" |
| R8 | Six application roles | PD-explicit | "Contributor, Scorer, FunctionOwner, PortfolioCouncil, ValueAnalyst, Admin" |
| R9 | Workload identity for service-to-service auth | PD-explicit | "Managed Identity for service-to-service auth" |
| R10 | An enterprise LLM endpoint | PD-explicit | "An enterprise LLM endpoint" |
| R11 | LLM credential held in a managed secret store | PD-explicit | "with the key held in Key Vault" |
| R12 | Outbound HTTPS/443 to the LLM provider | PD-explicit | "outbound HTTPS (443) allow-listed to the provider" |
| R13 | Compute for the API tier | PD-explicit | "Compute for the API and web tiers" |
| R14 | Managed secret store | PD-explicit | "Azure Key Vault (secrets)" |
| R15 | Settings / feature-flag store | PD-explicit | "App Configuration (settings/feature flags)" |
| R16 | Edge ingress with WAF | PD-explicit | "Front Door / Application Gateway with WAF" |
| R17 | Private network with private data-plane connectivity | PD-explicit | "VNet + Private Endpoints … private data-plane connectivity" |
| R18 | TLS certificates for ingress | PD-explicit | "TLS certificates for secure ingress" |
| R19 | Centralised telemetry | PD-explicit | "Application Insights / Log Analytics for telemetry" |
| R20 | Static hosting for the compiled SPA | Stack-inherent | Vite build output is static; PD: "served by the API or a CDN" |
| R21 | SPA deep-link fallback to `index.html` | Stack-inherent | Client-side routing returns 404 at the origin without it |

### OPTIONAL

The PD gates these three behind explicit conditional language: *"and — where the
corresponding capabilities are enabled — Azure Service Bus (async/eventing),
Azure Cache for Redis, and Azure AI Search (vector/hybrid search)."*

That sentence is the entire evidence base. Whether BCT enables any of them is a
property of the code, which is unavailable.

| # | Requirement | Evidence | Default taken |
|---|---|---|---|
| O1 | Async / eventing queue | PD-conditional | Implemented, **disabled** in all environments |
| O2 | Distributed cache | PD-conditional | Implemented, **disabled** in all environments |
| O3 | Vector / hybrid search | PD-conditional | Implemented, **disabled** in all environments |

Each is a real, complete module gated by an `enable_*` flag defaulting to
`false`, so nothing is provisioned until the code is inspected and the flag is
deliberately turned on. This satisfies "do not deploy a component the
application does not need" while avoiding a rewrite later.

### PD-ALTERNATIVE — decision required, made and documented

| # | Choice | PD wording | Resolution |
|---|---|---|---|
| A1 | Azure OpenAI **or** Anthropic Claude | "Azure OpenAI (endpoint + model deployment) **or** Anthropic Claude" | Both paths implemented — see ADR-008 |
| A2 | App Service **or** AKS/containers | "Azure App Service (with deployment slots) **or** AKS/containers" | ECS Fargate — see ADR-001 |
| A3 | SPA served by the API **or** by a CDN | "served by the API or a CDN" | S3 + CloudFront — see ADR-002 |

### NOT REQUIRED

| Requirement | Basis |
|---|---|
| Node.js on the hosting tier | PD states explicitly: "not required at runtime" |
| Kubernetes control plane | No PD requirement; ADR-001 selects ECS |
| Public database endpoint | Contradicted by PD ("private data-plane connectivity") and by the brief |
| Long-lived cloud access keys | Contradicted by PD ("Managed Identity … no connection strings") |

### UNKNOWN / NEEDS CONFIRMATION

Every item here is a genuine gap that only the source code can close. Each is
listed with the specific artefact that would resolve it.

| # | Question | Resolving artefact | Impact if the assumption is wrong |
|---|---|---|---|
| U1 | Is the API already containerised? | `Dockerfile`, `docker-compose.yml` | A reference Dockerfile is supplied; real project paths must be substituted |
| U2 | What HTTP port does the container bind? | `ASPNETCORE_URLS`, `launchSettings.json`, `Dockerfile EXPOSE` | Assumed **8080** (the .NET 8 container default). Wrong value breaks the ALB health check |
| U3 | Is there a health endpoint, and at what path? | `Program.cs` — `MapHealthChecks` | Assumed **`/healthz`**. Wrong path fails target-group health and blocks deployment |
| U4 | Does the app read Redis? | `StackExchange.Redis` in `.csproj`; `IDistributedCache` registration | O2 stays off; enabling later is a flag change |
| U5 | Does the app publish/consume messages? | `Azure.Messaging.ServiceBus` in `.csproj` | O1 stays off |
| U6 | Does the app perform vector/hybrid search? | `Azure.Search.Documents` in `.csproj` | O3 stays off |
| U7 | Which LLM SDK is in use? | `Azure.AI.OpenAI` vs `Anthropic.SDK` vs raw `HttpClient` | Determines whether Bedrock IAM or an egress-only path applies (ADR-008) |
| U8 | Does the app store user files/blobs? | `Azure.Storage.Blobs` in `.csproj` | No object store for user data is provisioned |
| U9 | Are there background/scheduled jobs? | `IHostedService`, Hangfire, Quartz | Single always-on service assumed; no scheduled task definitions |
| U10 | Does the app send email? | SMTP config, SendGrid/ACS packages | No SES identity provisioned |
| U11 | Entra tenant ID, API client ID, audience | `appsettings.json` → `AzureAd` section | Exposed as Terraform variables with no defaults; deployment fails fast until supplied |
| U12 | How are Entra groups mapped to the six roles? | authorization policy registration | Role names provisioned; claim-to-policy mapping is application-side |
| U13 | EF Core target: how are migrations run? | startup `Database.Migrate()` vs `dotnet ef` in CI | ADR-010 assumes a gated CI step, not startup migration |
| U14 | Expected request volume / concurrency | load test results, existing telemetry | Dev sizing chosen small; production sizing is a placeholder pending real numbers |
| U15 | Data residency / compliance regime | organisational policy | `us-east-1` per requester instruction; no residency controls encoded |

---

## Authentication flow

Source: PD. Not verified against code.

The PD states Microsoft Entra ID as the tenant, with app registrations for OIDC
sign-in and JWT validation, and Entra group → role mapping for six roles. The
resulting flow, and the AWS-side decision, are covered in ADR-005 — the summary
is that **Entra ID is retained as the direct token issuer** and Cognito is
deliberately *not* introduced.

```
Browser ──▶ Entra ID (OIDC authorization code + PKCE)
   │              │
   │        id_token / access_token  (aud = BCT API app registration)
   ▼              ▼
CloudFront ──▶ ALB ──▶ ECS task (ASP.NET Core)
                          │
                          ├─ JWT bearer validation against
                          │  login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration
                          └─ authorization policies keyed on the groups/roles claim
```

Nothing in this flow terminates on an AWS identity service. AWS IAM is used only
for *service-to-service* authorization (R9): the ECS task role replaces Managed
Identity for reaching Secrets Manager, S3, Bedrock and CloudWatch.

## Authorization model

Source: PD. Six roles, no code-verified policy definitions.

`Contributor` · `Scorer` · `FunctionOwner` · `PortfolioCouncil` · `ValueAnalyst` · `Admin`

The PD also describes an org hierarchy (service line → department → team) "synced
from your directory/HR feed". **No infrastructure is provisioned for this sync** —
there is no evidence of a sync mechanism, schedule, or source system, and
inventing one would violate the brief. Flagged as U12 and as a gap in
`docs/deployment.md`.

## External integrations

| Integration | Evidence | Infrastructure consequence |
|---|---|---|
| Enterprise LLM provider | PD-explicit (R10–R12) | Egress on 443; credential in Secrets Manager; Bedrock IAM if AWS-native |
| Microsoft Entra ID | PD-explicit (R7) | Egress on 443 to `login.microsoftonline.com`; no inbound path |
| Directory / HR feed | PD, mechanism unspecified | **None provisioned** — see U12 |

## Data dependencies

| Store | Evidence | Decision |
|---|---|---|
| Relational, SQL Server dialect | PD-explicit (R2) | RDS for SQL Server — ADR-003 |
| Schema migrations | PD-explicit (R3) | Gated CI step — ADR-010 |
| Cache | PD-conditional (O2) | Off by default |
| Search index | PD-conditional (O3) | Off by default |
| Object/blob storage for user data | No evidence (U8) | **Not provisioned** |

## Deployment assumptions

Every assumption below is load-bearing and unverified. They are repeated in
`terraform/README.md` because they must be checked before the first apply.

1. The API listens on **HTTP 8080** inside the container; TLS terminates at the ALB. (U2)
2. A health endpoint exists at **`/healthz`** returning 200. (U3)
3. The API is stateless and horizontally scalable — no session affinity, no local disk state. (U9)
4. The SPA is deployed as static files, not served by the API. (A3)
5. Migrations run as a **deliberate, gated CI step**, never automatically at container start. (ADR-010)
6. Entra tenant/client identifiers are supplied at deploy time as variables. (U11)

## Cloud dependencies to be replaced

| Azure dependency | Evidence | Replacement | Detail |
|---|---|---|---|
| Azure SQL Database | R2 | RDS for SQL Server | ADR-003 |
| Managed Identity | R9 | IAM task role | ADR-004 |
| Key Vault | R11, R14 | Secrets Manager + KMS | — |
| App Configuration | R15 | AWS AppConfig | ADR-009 |
| App Service / AKS | R13, A2 | ECS Fargate | ADR-001 |
| Front Door + App Gateway + WAF | R16 | CloudFront + ALB + WAFv2 | ADR-002 |
| VNet + Private Endpoints | R17 | VPC + VPC endpoints | ADR-006 |
| App Insights / Log Analytics | R19 | CloudWatch Logs + alarms | ADR-007 |
| Azure OpenAI | R10, A1 | Bedrock, or egress to Anthropic | ADR-008 |
| Entra ID | R7 | **retained, not replaced** | ADR-005 |
| Service Bus / Redis / AI Search | O1–O3 | SQS / ElastiCache / OpenSearch, all disabled | ADR-011 |

---

## What must happen before this document can be trusted

This discovery is incomplete by cause, not by choice. To close it:

1. Push the BCT source to `<APPLICATION_REPO>`, or supply a populated remote.
2. Re-run discovery against the real tree.
3. Resolve U1–U15 — U2, U3 and U11 are deployment-blocking; the rest change scope.
4. Reconcile this classification with the code and revise the inventory.

Until then, treat `docs/aws-resource-inventory.md` as **the infrastructure implied
by the prerequisites document**, not as the infrastructure BCT requires.
