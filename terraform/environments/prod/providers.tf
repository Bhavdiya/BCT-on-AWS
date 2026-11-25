provider "aws" {
  region = var.region
}

# CloudFront-scoped WAF Web ACLs and CloudFront viewer certificates can only be
# created in us-east-1, whatever region the rest of the stack runs in. This is a
# service constraint, not a deployment choice, so it stays literal.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
