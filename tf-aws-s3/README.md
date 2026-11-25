# tf-aws-s3

Private, versioned, KMS-encrypted S3 bucket, optionally readable by a CloudFront OAC.

**Azure equivalent:** Blob Storage / Static Website

## Usage

```hcl
module "s3" {
  source = "git::https://gitlab.com/<GITLAB_GROUP>/tf-aws-s3.git?ref=main"

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
