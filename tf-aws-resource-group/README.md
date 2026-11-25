# tf-aws-resource-group

Tag-based AWS Resource Group used as the governance boundary for an application's resources.

**Azure equivalent:** Resource Group

## Usage

```hcl
module "resource-group" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-resource-group.git?ref=main"

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
