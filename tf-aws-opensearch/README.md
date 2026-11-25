# tf-aws-opensearch

OpenSearch domain in the VPC for vector and hybrid search.

**Azure equivalent:** Azure AI Search

## Usage

```hcl
module "opensearch" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-opensearch.git?ref=main"

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
