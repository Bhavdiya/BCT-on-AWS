# tf-aws-rds-sqlserver

RDS for SQL Server in private subnets, KMS-encrypted, master password held in Secrets Manager.

**Azure equivalent:** Azure SQL Database

## Usage

```hcl
module "rds-sqlserver" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-rds-sqlserver.git?ref=main"

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
