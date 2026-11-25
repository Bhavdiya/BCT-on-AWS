# Disaster recovery

**No RPO or RTO targets were supplied.** That is a business decision, not an
architectural one, and it determines which of the options below is correct. What
follows is what the current build actually delivers, and what each improvement
would cost.

---

## What is protected today

| Asset | Mechanism | Recovery point | Recovery time |
|---|---|---|---|
| Database | RDS automated backups, point-in-time recovery | ~5 min | 30–90 min |
| Database | Manual/final snapshots | on demand | 30–90 min |
| Front-end bundle | S3 versioning | every release | minutes |
| Container images | ECR, last 30 retained | every release | minutes |
| Infrastructure definition | Terraform in git | every commit | 30–60 min to rebuild |
| Terraform state | S3 versioning on the state bucket | every apply | minutes |
| Secrets | Secrets Manager, 30-day recovery window (7 in dev) | continuous | minutes |
| Configuration | AppConfig hosted versions | every deployment | minutes |

Backup retention: 7 days dev, 14 uat, **35 prod**.

## What is *not* protected

Stated plainly.

1. **Everything is single-Region.** A full us-east-1 failure takes the
   application down. There is no standby, no cross-Region replica, no
   cross-Region snapshot copy.
2. **RDS automated backups do not leave the Region.** This is the gap against
   the PD's "geo-redundancy per your data policy" — Azure geo-redundant backup
   has no like-for-like default here; it must be built.
3. **No tested restore.** An untested backup is a hypothesis. See the drill below.
4. **The state bucket is single-Region** too. Versioned, but not replicated.
5. **KMS keys are regional.** A cross-Region restore needs a multi-Region key or
   a re-encrypt step. The current key is **not** multi-Region — changing that
   requires replacing the key, which means re-encrypting everything, so it is a
   decision to take before production data exists, not after.

---

## Failure scenarios

| Scenario | Blast radius today | Recovery |
|---|---|---|
| One ECS task dies | None. ALB drains it, the service replaces it. | Automatic |
| One AZ fails | **prod:** none — 3 AZs, Multi-AZ RDS, NAT per AZ. **dev/uat:** private egress dies if the NAT's AZ is lost. | Automatic in prod |
| RDS primary fails | **prod:** automatic failover, 60–120s. **dev/uat:** single instance, restore required. | Automatic in prod |
| Bad deploy | Circuit breaker rolls back. | Automatic, ~5 min |
| Bad migration | **Not automatic.** PITR to a new instance, then repoint. | 30–90 min |
| Accidental table drop | PITR to just before it. | 30–90 min |
| Region failure | **Total outage. No recovery path exists today.** | Rebuild from Terraform into another Region + restore a snapshot that must first be copied there |
| State file corruption | Restore the previous S3 object version. | Minutes |
| Compromised credential | No long-lived credentials exist; revoke the role session and rotate the RDS secret. | Minutes |

---

## Improving the position

Presented as a decision, not a recommendation, because the right answer depends
on the RPO/RTO nobody has stated yet.

### Option A — Cross-Region snapshot copy · *recommended starting point*

An EventBridge rule plus a small Lambda copies the daily automated snapshot to a
second Region.

- **RPO** ~24h · **RTO** 2–4h
- **Cost** ~$30–60/mo (snapshot storage + cross-Region transfer)
- **Effort** low — one Lambda, one rule, a multi-Region KMS key
- Closes the "geo-redundancy" gap at the lowest cost. If one thing is done, this.

### Option B — Cross-Region read replica

- **RPO** seconds to minutes · **RTO** 15–30 min
- **Cost** ~$1,400/mo — a second full SQL Server instance, licence included
- **Note** RDS for SQL Server does **not** support cross-Region read replicas in
  the same way PostgreSQL and MySQL do; it requires the Multi-AZ-with-readable-
  standby configuration or a self-managed log-shipping arrangement. Verify
  feasibility for the chosen edition before committing to this.

### Option C — Warm standby in a second Region

Full stack deployed at minimum capacity, Route 53 health-check failover.

- **RPO** minutes · **RTO** 15–30 min
- **Cost** roughly +60–80% of the production bill
- **Effort** high — the Terraform supports it (parameterised by region), but
  data replication, secret replication and DNS failover all need building

### Option D — Accept single-Region

- **RPO/RTO** hours to days, dependent on rebuilding and restoring
- **Cost** zero additional
- Defensible for an internal business-case tool. **It should be an explicit,
  documented acceptance, not an accident.** That is the point of this section.

---

## Rebuilding from nothing

If the Region is lost and Option A snapshots exist:

```sh
# 1. State bucket in the recovery Region
cd terraform/bootstrap
terraform apply -var region=us-west-2 -var state_bucket_name=bct-tfstate-dr-<account>

# 2. Restore the database from the copied snapshot FIRST.
#    Terraform does not own this instance; it is imported afterwards.
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier bct-prod \
  --db-snapshot-identifier <copied-snapshot> \
  --region us-west-2

# 3. Stand the stack up, pointed at the recovery Region
cd ../environments/prod
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -var region=us-west-2

# 4. Repoint DNS
```

Steps that will bite, and are easy to forget under pressure:

- The **KMS key is regional**. A snapshot encrypted with the primary Region's
  key cannot be restored elsewhere unless it was re-encrypted during copy.
- **Secrets do not replicate** unless configured to. Add replica Regions to each
  secret, or accept re-populating them by hand.
- **ECR images are regional.** Replication must be configured in advance or the
  images rebuilt.
- The **CloudFront certificate is always us-east-1** — unaffected by the loss of
  the application Region, which is one thing in your favour.

---

## The drill

An untested backup is a hypothesis. Quarterly, in a non-production account:

1. Restore the latest production snapshot to a new instance.
2. Point a scratch ECS service at it.
3. Confirm the application starts and serves real data.
4. **Record the wall-clock time.** That number is your actual RTO; the estimates
   above are not.
5. Destroy the restored instance.

If this has never been run, the RTO figures in this document are guesses.
