# tf-aws-ecr

Private ECR repository with image scanning and an expiry lifecycle policy.

**Azure equivalent:** Azure Container Registry

## Usage

```hcl
module "ecr" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-ecr.git?ref=main"

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
