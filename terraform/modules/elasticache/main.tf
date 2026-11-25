resource "aws_elasticache_subnet_group" "this" {
  name       = var.name_prefix
  subnet_ids = var.subnet_ids
}

# transit_encryption_mode is required alongside transit encryption so an
# existing client fleet can migrate without a connection break.
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name_prefix
  description          = "Cache for ${var.name_prefix}"

  engine               = "valkey"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  parameter_group_name = var.parameter_group_name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_id]

  automatic_failover_enabled = var.num_cache_clusters > 1
  multi_az_enabled           = var.num_cache_clusters > 1

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn

  snapshot_retention_limit   = var.snapshot_retention_limit
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = true
  apply_immediately          = false
}
