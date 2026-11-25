output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnets, holding only the load balancer and NAT gateways"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnets for ECS tasks"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Private database subnets with no route to the internet"
  value       = aws_subnet.data[*].id
}

output "availability_zones" {
  description = "AZs the subnets span"
  value       = local.azs
}

output "endpoints_security_group_id" {
  description = "Security group protecting the interface endpoints"
  value       = aws_security_group.endpoints.id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs"
  value       = aws_nat_gateway.this[*].id
}
