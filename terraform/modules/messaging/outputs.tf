output "queue_urls" {
  description = "Queue URLs keyed by logical name"
  value       = { for key, queue in aws_sqs_queue.this : key => queue.url }
}

output "queue_arns" {
  description = "Queue ARNs keyed by logical name, for scoping the task role"
  value       = { for key, queue in aws_sqs_queue.this : key => queue.arn }
}

output "dlq_arns" {
  description = "Dead-letter queue ARNs keyed by logical name"
  value       = { for key, queue in aws_sqs_queue.dlq : key => queue.arn }
}
