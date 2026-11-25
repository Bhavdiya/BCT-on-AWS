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

data "aws_caller_identity" "current" {}

resource "aws_bedrock_guardrail" "this" {
  name                      = var.name
  description               = "AI usage policy for ${var.resource_tags["tag_app_name"]}"
  blocked_input_messaging   = var.blocked_message
  blocked_outputs_messaging = var.blocked_message

  content_policy_config {
    dynamic "filters_config" {
      for_each = toset(var.content_filters)

      content {
        type = filters_config.value
        # PROMPT_ATTACK only supports an input filter.
        input_strength  = "HIGH"
        output_strength = filters_config.value == "PROMPT_ATTACK" ? "NONE" : "HIGH"
      }
    }
  }

  sensitive_information_policy_config {
    dynamic "pii_entities_config" {
      for_each = toset(var.blocked_pii_entities)

      content {
        type   = pii_entities_config.value
        action = "ANONYMIZE"
      }
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

data "aws_iam_policy_document" "invoke" {
  statement {
    sid = "InvokeApprovedModels"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = concat(
      [for model in var.allowed_model_ids : "arn:aws:bedrock:${var.region}::foundation-model/${model}"],
      [for profile in var.allowed_inference_profile_ids : "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${profile}"],
    )
  }

  statement {
    sid       = "ApplyGuardrail"
    actions   = ["bedrock:ApplyGuardrail"]
    resources = [aws_bedrock_guardrail.this.guardrail_arn]
  }
}

resource "aws_iam_policy" "invoke" {
  name        = "${var.name}-invoke"
  description = "Least privilege Bedrock access for ${var.resource_tags["tag_app_name"]}"
  policy      = data.aws_iam_policy_document.invoke.json

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}
