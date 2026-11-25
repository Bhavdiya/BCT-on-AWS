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

resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = "Edge protection for ${var.resource_tags["tag_app_name"]}"
  scope       = var.scope

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = { for index, group in var.managed_rule_groups : group => index }

    content {
      name     = rule.key
      priority = rule.value

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.key
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.key
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimitPerIp"
    priority = length(var.managed_rule_groups)

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIp"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.log_destination_arn == null ? 0 : 1

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [var.log_destination_arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}
