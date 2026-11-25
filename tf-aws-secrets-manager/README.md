# tf-aws-secrets-manager

Secrets Manager secret encrypted with a CMK, with optional automatic rotation.

**Azure equivalent:** Key Vault (secrets)

## Usage

```hcl
module "secrets-manager" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-secrets-manager.git?ref=main"

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
