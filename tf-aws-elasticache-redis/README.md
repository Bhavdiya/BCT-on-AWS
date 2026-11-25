# tf-aws-elasticache-redis

ElastiCache for Redis replication group in private subnets, encrypted in transit and at rest.

**Azure equivalent:** Azure Cache for Redis

## Usage

```hcl
module "elasticache-redis" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-elasticache-redis.git?ref=main"

  # see tests/terraform.tfvars for a complete example
}
```

## Testing

```sh
cd tests
terraform init
terraform plan
```

## Tagging

Every resource carries the standard organisation tag set built from `resource_tags`:
`Created`, `AppRef`, `Environment`, `Location`, `BusinessUnit`, `ApplicationName`,
`ApplicationOwner`, merged with `additional_tags`. `Created` is stamped once and
then ignored on subsequent plans.
