data "aws_caller_identity" "current" {}

locals {
  tls_enabled   = var.certificate_arn != null
  listener_port = local.tls_enabled ? 443 : 80
}
data "aws_elb_service_account" "current" {}

# ---------------------------------------------------------------------------
# Access log bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket        = "${var.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ALB access logs are written with SSE-S3 only. The service cannot use a CMK
# for this delivery path, so aws:kms here would silently drop every log.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire"
    status = "Enabled"

    filter {}

    expiration {
      days = var.access_log_retention_days
    }
  }
}

data "aws_iam_policy_document" "logs" {
  count = var.enable_access_logs ? 1 : 0

  # Older regions, including us-east-1, deliver logs as a regional ELB account
  # principal rather than as a service principal.
  statement {
    sid       = "ELBAccountWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
  }

  statement {
    sid       = "LogDeliveryWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.logs[0].arn, "${aws_s3_bucket.logs[0].arn}/*"]

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

resource "aws_s3_bucket_policy" "logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket     = aws_s3_bucket.logs[0].id
  policy     = data.aws_iam_policy_document.logs[0].json
  depends_on = [aws_s3_bucket_public_access_block.logs]
}

# ---------------------------------------------------------------------------
# Load balancer
# ---------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.name_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = 120

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []

    content {
      bucket  = aws_s3_bucket.logs[0].id
      prefix  = "alb"
      enabled = true
    }
  }

  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_lb_target_group" "this" {
  name        = var.name_prefix
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.this.arn
  port              = local.listener_port
  protocol          = local.tls_enabled ? "HTTPS" : "HTTP"
  ssl_policy        = local.tls_enabled ? var.ssl_policy : null
  certificate_arn   = var.certificate_arn

  # Default is to reject. Only a request carrying the shared origin header from
  # CloudFront is forwarded, which closes the gap left by the prefix list: any
  # other CloudFront customer's distribution also originates from those IPs.
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Direct access to this origin is not permitted."
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "from_cloudfront" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  dynamic "condition" {
    for_each = var.origin_verify_secret == null ? [] : [var.origin_verify_secret]

    content {
      http_header {
        http_header_name = "X-Origin-Verify"
        values           = [condition.value]
      }
    }
  }

  # With no shared secret configured the rule still needs a condition, so it
  # matches every path and the listener behaves as a plain forward.
  dynamic "condition" {
    for_each = var.origin_verify_secret == null ? [1] : []

    content {
      path_pattern {
        values = ["/*"]
      }
    }
  }
}
