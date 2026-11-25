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

locals {
  suffix   = var.fifo_queue ? ".fifo" : ""
  sse_only = var.kms_key_arn == null
}

resource "aws_sqs_queue" "dlq" {
  name                        = "${var.name}-dlq${local.suffix}"
  fifo_queue                  = var.fifo_queue
  message_retention_seconds   = var.dlq_retention_seconds
  kms_master_key_id           = var.kms_key_arn
  sqs_managed_sse_enabled     = local.sse_only
  content_based_deduplication = var.fifo_queue

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_sqs_queue" "this" {
  name                        = "${var.name}${local.suffix}"
  fifo_queue                  = var.fifo_queue
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  kms_master_key_id           = var.kms_key_arn
  sqs_managed_sse_enabled     = local.sse_only
  content_based_deduplication = var.fifo_queue

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}
