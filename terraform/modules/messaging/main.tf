resource "aws_sqs_queue" "dlq" {
  for_each = toset(var.queues)

  name                      = "${var.name_prefix}-${each.value}-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn
}

resource "aws_sqs_queue" "this" {
  for_each = toset(var.queues)

  name                       = "${var.name_prefix}-${each.value}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.value].arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  for_each = toset(var.queues)

  queue_url = aws_sqs_queue.dlq[each.value].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this[each.value].arn]
  })
}

# A message sitting in a dead-letter queue means processing failed repeatedly
# and nothing else will notice.
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  for_each = toset(var.queues)

  alarm_name          = "${var.name_prefix}-${each.value}-dlq-not-empty"
  alarm_description   = "Messages have landed in the ${each.value} dead-letter queue"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq[each.value].name
  }
}
