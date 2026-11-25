data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

resource "aws_bedrock_guardrail" "this" {
  count = var.create_guardrail ? 1 : 0

  name                      = var.name_prefix
  description               = "AI usage policy for ${var.name_prefix}"
  blocked_input_messaging   = var.blocked_message
  blocked_outputs_messaging = var.blocked_message

  content_policy_config {
    dynamic "filters_config" {
      for_each = toset(var.content_filters)

      content {
        type           = filters_config.value
        input_strength = "HIGH"
        # PROMPT_ATTACK is an input-side filter only; Bedrock rejects an output
        # strength on it.
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
}

# Model invocation is scoped to the approved models only. Both ARN shapes are
# granted because a cross-region inference profile has an account-scoped ARN
# that does not match the bare foundation-model ARN.
data "aws_iam_policy_document" "invoke" {
  statement {
    sid = "InvokeApprovedModels"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = concat(
      [
        for model in var.allowed_model_ids :
        "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}::foundation-model/${model}"
      ],
      [
        for profile in var.allowed_inference_profile_ids :
        "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${profile}"
      ],
    )
  }

  dynamic "statement" {
    for_each = var.create_guardrail ? [1] : []

    content {
      sid       = "ApplyGuardrail"
      actions   = ["bedrock:ApplyGuardrail"]
      resources = [aws_bedrock_guardrail.this[0].guardrail_arn]
    }
  }
}

resource "aws_iam_policy" "invoke" {
  name        = "${var.name_prefix}-bedrock-invoke"
  description = "Least-privilege Bedrock access for ${var.name_prefix}"
  policy      = data.aws_iam_policy_document.invoke.json
}
