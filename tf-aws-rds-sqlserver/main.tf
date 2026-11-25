locals {
  tags = merge(var.additional_tags, {
    Created          = formatdate("YYYY-MM-DD", timestamp())
    AppRef           = var.resource_group_identifier
    Environment      = var.resource_tags["tag_env"]
    Location         = "aws ${lower(var.region)}"
    BusinessUnit     = var.resource_tags["tag_business_unit"]
    ApplicationName  = var.resource_tags["tag_app_name"]
    ApplicationOwner = var.resource_tags["tag_app_owner"]
  })
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-db"
  description = "SQL Server access for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SQL Server from the application tier"
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  tags = merge(local.tags, { Name = "${var.name}-db" })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

# RDS for SQL Server does not support IAM database authentication, so the managed
# identity equivalent is: task role -> Secrets Manager -> rotated master credential.
# Switch to Aurora PostgreSQL if true IAM auth is a hard requirement.
resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  license_model  = "license-included"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  username                      = var.master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final"

  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn
  enabled_cloudwatch_logs_exports = ["error", "agent"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["Created"]]
  }
}
