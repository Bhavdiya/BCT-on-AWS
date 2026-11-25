resource "aws_wafv2_web_acl" "this" {
  name        = var.name_prefix
  description = "Edge protection for ${var.name_prefix}"
  scope       = var.scope

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = { for index, group in var.managed_rule_groups : group => index }

    content {
      name     = rule.key
      priority = rule.value

      # count_only turns the whole managed set into observation mode. Enforcing
      # an unfamiliar rule set on day one is the usual cause of a WAF being
      # switched off entirely after it blocks legitimate traffic.
      override_action {
        dynamic "none" {
          for_each = var.count_only ? [] : [1]
          content {}
        }

        dynamic "count" {
          for_each = var.count_only ? [1] : []
          content {}
        }
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
    metric_name                = var.name_prefix
    sampled_requests_enabled   = true
  }
}
