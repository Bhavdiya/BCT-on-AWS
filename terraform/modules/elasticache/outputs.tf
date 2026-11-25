output "primary_endpoint_address" {
  description = "Write endpoint"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Read endpoint spread across replicas"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Listener port"
  value       = aws_elasticache_replication_group.this.port
}
