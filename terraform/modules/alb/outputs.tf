output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix, used as a CloudWatch metric dimension"
  value       = aws_lb.this.arn_suffix
}

output "dns_name" {
  description = "DNS name, used as the CloudFront API origin"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Hosted zone of the load balancer, for a Route 53 alias"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Target group the ECS service registers into"
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix, used as a CloudWatch metric dimension"
  value       = aws_lb_target_group.this.arn_suffix
}

output "access_log_bucket" {
  description = "Access log bucket name, null when disabled"
  value       = try(aws_s3_bucket.logs[0].id, null)
}

output "listener_port" {
  description = "Port the listener accepts on, 443 with a certificate and 80 without"
  value       = local.listener_port
}

output "listener_protocol" {
  description = "Protocol CloudFront must use to reach this origin"
  value       = local.tls_enabled ? "https-only" : "http-only"
}
