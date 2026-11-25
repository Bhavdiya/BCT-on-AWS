# Partial backend configuration. Bucket and region are supplied at init time so
# the same code works across accounts and regions:
#
#   terraform init -backend-config=backend.hcl
#
# Locking uses S3 conditional writes (use_lockfile), which replaced the
# DynamoDB lock table in Terraform 1.10. See ADR-013.
terraform {
  backend "s3" {
    key          = "uat/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
