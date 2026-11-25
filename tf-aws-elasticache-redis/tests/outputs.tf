output "primary_endpoint_address" {
  description = "Endpoint for writes"
  value       = module.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Endpoint for reads spread across replicas"
  value       = module.redis.reader_endpoint_address
}

output "security_group_id" {
  description = "Security group of the cache"
  value       = module.redis.security_group_id
}
