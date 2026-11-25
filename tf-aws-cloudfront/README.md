# tf-aws-cloudfront

CloudFront distribution serving an S3 SPA origin and an ALB API origin behind WAF.

**Azure equivalent:** Azure Front Door

## Usage

```hcl
module "cloudfront" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-cloudfront.git?ref=main"

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
