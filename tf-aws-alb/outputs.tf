output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "DNS name of the load balancer, use this as a CloudFront origin or Route 53 alias target"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the load balancer, for a Route 53 alias record"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group, pass this to the ECS service"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Security group of the load balancer, allow this on the container security group"
  value       = aws_security_group.this.id
}
