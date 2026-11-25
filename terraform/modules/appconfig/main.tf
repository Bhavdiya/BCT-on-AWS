resource "aws_appconfig_application" "this" {
  name        = var.name_prefix
  description = "Settings and feature flags for ${var.name_prefix}"
}

resource "aws_appconfig_environment" "this" {
  name           = var.environment
  application_id = aws_appconfig_application.this.id
}

resource "aws_appconfig_configuration_profile" "flags" {
  name           = "${var.name_prefix}-flags"
  application_id = aws_appconfig_application.this.id
  location_uri   = "hosted"
  type           = "AWS.AppConfig.FeatureFlags"
}

resource "aws_appconfig_configuration_profile" "settings" {
  name           = "${var.name_prefix}-settings"
  application_id = aws_appconfig_application.this.id
  location_uri   = "hosted"
  type           = "AWS.Freeform"
}

# Flag and setting content is deliberately not managed here. A hosted
# configuration version in state would fight with every runtime flag change
# made through the console or API.
resource "aws_appconfig_deployment_strategy" "this" {
  name                           = var.name_prefix
  description                    = "Linear rollout with a bake period"
  deployment_duration_in_minutes = var.deployment_duration_in_minutes
  final_bake_time_in_minutes     = var.final_bake_time_in_minutes
  growth_factor                  = var.growth_factor
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"
}
