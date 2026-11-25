# tf-aws-waf

WAFv2 Web ACL with AWS managed rule groups and a rate limit rule.

**Azure equivalent:** WAF policy on Front Door / Application Gateway

## Usage

```hcl
module "waf" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-waf.git?ref=main"

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
