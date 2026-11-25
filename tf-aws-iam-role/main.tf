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

data "aws_iam_policy_document" "assume" {
  statement {
    sid     = "AllowServiceAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.assume_role_services
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = coalesce(var.assume_role_policy_json, data.aws_iam_policy_document.assume.json)
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = var.max_session_duration

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
