# tf-aws-acm-certificate

ACM public certificate with optional Route 53 DNS validation.

**Azure equivalent:** TLS certificate (Key Vault / App Service Managed Cert)

## Usage

```hcl
module "acm-certificate" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-acm-certificate.git?ref=main"

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
