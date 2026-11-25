# tf-aws-ecs-fargate

ECS Fargate cluster, task definition, service and target-tracking autoscaling.

**Azure equivalent:** App Service

## Usage

```hcl
module "ecs-fargate" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-ecs-fargate.git?ref=main"

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
