output "log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "Application log group ARN"
  value       = aws_cloudwatch_log_group.app.arn
}

output "alarm_topic_arn" {
  description = "SNS topic alarms publish to"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "Dashboard name, null when not created"
  value       = try(aws_cloudwatch_dashboard.this[0].dashboard_name, null)
}
