# tf-aws-cognito-user-pool

Cognito user pool federated to an external OIDC/SAML IdP, with role groups and an app client.

**Azure equivalent:** Microsoft Entra ID (app registration + group mapping)

## Usage

```hcl
module "cognito-user-pool" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-cognito-user-pool.git?ref=main"

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
