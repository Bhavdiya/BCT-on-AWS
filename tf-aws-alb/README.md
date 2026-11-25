# tf-aws-alb

Internet-facing or internal ALB with HTTPS listener, HTTP redirect and a target group.

**Azure equivalent:** Application Gateway

## Usage

```hcl
module "alb" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-alb.git?ref=main"

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
