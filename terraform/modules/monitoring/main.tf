data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_sns_topic" "alarms" {
  name              = "${var.name_prefix}-alarms"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alarm_email_addresses)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

locals {
  ecs_alarms_enabled = var.ecs_cluster_name != null && var.ecs_service_name != null
  alb_alarms_enabled = var.alb_arn_suffix != null && var.target_group_arn_suffix != null
  db_alarms_enabled  = var.db_instance_id != null
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  count = local.ecs_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-cpu-high"
  alarm_description   = "ECS service CPU sustained above ${var.cpu_alarm_threshold}%"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  count = local.ecs_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-memory-high"
  alarm_description   = "ECS service memory sustained above ${var.memory_alarm_threshold}%"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.memory_alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = local.alb_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-target-5xx"
  alarm_description   = "The API is returning server errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.http_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Missing data is breaching here on purpose: no reporting healthy hosts is the
# outage, and treating it as "not breaching" would silence the one alarm that
# matters most.
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count = local.alb_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-no-healthy-targets"
  alarm_description   = "No healthy targets are registered, the API is down"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  count = local.db_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "Database CPU sustained above 85%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "db_storage" {
  count = local.db_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-storage-low"
  alarm_description   = "Database free storage is running out"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.db_free_storage_bytes_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# A conditional cannot return tuples of different lengths, so each widget is
# defined once and included through a range() comprehension instead.
locals {
  widget_requests = {
    type   = "metric"
    width  = 12
    height = 6
    properties = {
      title   = "Request volume and errors"
      region  = data.aws_region.current.region
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
        [".", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum" }],
        [".", "HTTPCode_Target_4XX_Count", ".", ".", { stat = "Sum" }],
      ]
    }
  }

  widget_latency = {
    type   = "metric"
    width  = 12
    height = 6
    properties = {
      title   = "Target response time"
      region  = data.aws_region.current.region
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50" }],
        ["...", { stat = "p95" }],
        ["...", { stat = "p99" }],
      ]
    }
  }

  widget_service = {
    type   = "metric"
    width  = 12
    height = 6
    properties = {
      title   = "Service utilisation"
      region  = data.aws_region.current.region
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name, { stat = "Average" }],
        [".", "MemoryUtilization", ".", ".", ".", ".", { stat = "Average" }],
      ]
    }
  }

  widget_database = {
    type   = "metric"
    width  = 12
    height = 6
    properties = {
      title   = "Database"
      region  = data.aws_region.current.region
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { stat = "Average" }],
        [".", "DatabaseConnections", ".", ".", { stat = "Sum" }],
        [".", "FreeStorageSpace", ".", ".", { stat = "Average" }],
      ]
    }
  }

  dashboard_widgets = concat(
    [for _ in range(local.alb_alarms_enabled ? 1 : 0) : local.widget_requests],
    [for _ in range(local.alb_alarms_enabled ? 1 : 0) : local.widget_latency],
    [for _ in range(local.ecs_alarms_enabled ? 1 : 0) : local.widget_service],
    [for _ in range(local.db_alarms_enabled ? 1 : 0) : local.widget_database],
  )
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = var.name_prefix
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
