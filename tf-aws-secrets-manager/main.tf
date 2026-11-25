locals {
  tags = merge(var.additional_tags, {
    Created          = formatdate("YYYY-MM-DD", timestamp())
    AppRef           = var.resource_group_identifier
    Environment      = var.resource_tags["tag_env"]
    Location         = "aws ${lower(var.region)}"
    BusinessUnit     = var.resource_tags["tag_business_unit"]
    ApplicationName  = var.resource_tags["tag_app_name"]
    ApplicationOwner = var.resource_tags["tag_app_owner"]
  })
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count = var.initial_value == null ? 0 : 1

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.initial_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.rotation_lambda_arn == null ? 0 : 1

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
