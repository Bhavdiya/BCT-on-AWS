# tf-aws-sqs

SQS queue with a dead-letter queue and CMK encryption.

**Azure equivalent:** Service Bus queue

## Usage

```hcl
module "sqs" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-sqs.git?ref=main"

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
