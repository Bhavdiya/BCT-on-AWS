# Bootstrap: creates the Terraform state bucket.
#
# This configuration keeps its own state locally and is applied once per
# account, before any environment. A stack cannot create the bucket that holds
# its own state, so this has to live outside the environments.
#
#   terraform -chdir=bootstrap init
#   terraform -chdir=bootstrap apply \
#     -var 'region=<AWS_REGION>' \
#     -var 'state_bucket_name=<PROJECT_NAME>-tfstate-<ACCOUNT_ID>'
#
# Commit the resulting terraform.tfstate here, or apply it once and treat the
# bucket as a known account fixture.

terraform {
  required_version = "~> 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "Region the state bucket is created in. No default: it must be supplied explicitly"
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique name for the state bucket"
  type        = string
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # State is the one thing that must never be casually destroyed: losing it
  # orphans every resource it tracks.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning is the recovery path from a corrupted or truncated state write.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "state" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket     = aws_s3_bucket.state.id
  policy     = data.aws_iam_policy_document.state.json
  depends_on = [aws_s3_bucket_public_access_block.state]
}

output "state_bucket_name" {
  description = "Bucket name to put in each environment's backend.hcl"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "Bucket ARN to pass to each environment as state_bucket_arn"
  value       = aws_s3_bucket.state.arn
}
