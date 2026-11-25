name              = "bedrock-test-example-bct"
allowed_model_ids = ["anthropic.claude-sonnet-4-5-20250929-v1:0"]

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
