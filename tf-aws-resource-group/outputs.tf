output "resource_group_id" {
  description = "The ID of the resource group"
  value       = aws_resourcegroups_group.this.id
}

output "resource_group_arn" {
  description = "The ARN of the resource group"
  value       = aws_resourcegroups_group.this.arn
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = aws_resourcegroups_group.this.name
}

output "resource_group_region" {
  description = "The region the resource group was created in"
  value       = var.region
}
