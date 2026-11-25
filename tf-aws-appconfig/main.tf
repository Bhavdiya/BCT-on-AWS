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

resource "aws_appconfig_application" "this" {
  name        = var.name
  description = var.description

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_appconfig_environment" "this" {
  name           = var.environment_name
  application_id = aws_appconfig_application.this.id

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_appconfig_configuration_profile" "this" {
  name           = var.name
  application_id = aws_appconfig_application.this.id
  location_uri   = "hosted"
  type           = var.profile_type

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_appconfig_deployment_strategy" "this" {
  name                           = var.name
  deployment_duration_in_minutes = var.deployment_duration_in_minutes
  final_bake_time_in_minutes     = var.final_bake_time_in_minutes
  growth_factor                  = var.growth_factor
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}
