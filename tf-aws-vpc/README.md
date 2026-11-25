# tf-aws-vpc

VPC with public/private subnets across N AZs, NAT egress, and PrivateLink endpoints.

**Azure equivalent:** Virtual Network + Private Endpoints

## Usage

```hcl
module "vpc" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-vpc.git?ref=main"

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
