# tf-aws-bedrock

Bedrock guardrail plus a least-privilege InvokeModel policy for the approved models.

**Azure equivalent:** Azure OpenAI

## Usage

```hcl
module "bedrock" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-bedrock.git?ref=main"

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
