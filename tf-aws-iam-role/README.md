# tf-aws-iam-role

Assumable IAM role with managed policy attachments and an optional inline policy.

**Azure equivalent:** Managed Identity

## Usage

```hcl
module "iam-role" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-iam-role.git?ref=main"

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
