# tf-aws-cloudwatch-log-group

CloudWatch log group with retention and CMK encryption.

**Azure equivalent:** Log Analytics Workspace

## Usage

```hcl
module "cloudwatch-log-group" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-cloudwatch-log-group.git?ref=main"

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
