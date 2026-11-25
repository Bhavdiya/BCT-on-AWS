output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.resource_group.resource_group_id
}

output "resource_group_arn" {
  description = "The ARN of the resource group"
  value       = module.resource_group.resource_group_arn
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.resource_group_name
}

output "resource_group_region" {
  description = "The region the resource group was created in"
  value       = module.resource_group.resource_group_region
}
