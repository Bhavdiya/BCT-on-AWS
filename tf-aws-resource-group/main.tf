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

resource "aws_resourcegroups_group" "this" {
  name        = var.name
  description = "Resources for ${var.resource_tags["tag_app_name"]} (${var.resource_group_identifier})"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "AppRef"
          Values = [var.resource_group_identifier]
        },
        {
          Key    = "Environment"
          Values = [var.resource_tags["tag_env"]]
        },
      ]
    })
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["Created"]]
  }
}
