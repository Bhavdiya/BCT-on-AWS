data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  zone_count = var.instance_count > 1 ? min(var.instance_count, length(var.subnet_ids), 3) : 1
}

resource "aws_opensearch_domain" "this" {
  domain_name    = var.name_prefix
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.instance_count > 1

    dynamic "zone_awareness_config" {
      for_each = var.instance_count > 1 ? [1] : []

      content {
        availability_zone_count = local.zone_count
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.volume_size
  }

  vpc_options {
    subnet_ids         = slice(var.subnet_ids, 0, local.zone_count)
    security_group_ids = [var.security_group_id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Fine-grained access control with no internal user database: the only way in
  # is as an IAM principal, so the task role is the sole identity.
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false

    master_user_options {
      master_user_arn = var.master_user_arn
    }
  }

  access_policies = data.aws_iam_policy_document.domain.json
}

data "aws_iam_policy_document" "domain" {
  statement {
    actions   = ["es:ESHttp*"]
    resources = ["arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${var.name_prefix}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.master_user_arn]
    }
  }
}
