output "replication_group_id" {
  description = "The replication group identifier"
  value       = aws_elasticache_replication_group.this.id
}

output "primary_endpoint_address" {
  description = "Endpoint for writes"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Endpoint for reads spread across replicas"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "security_group_id" {
  description = "Security group of the cache"
  value       = aws_security_group.this.id
}
