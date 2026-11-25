name          = "cognito-test-example-bct"
domain_prefix = "bct-test-example"
callback_urls = ["https://bct.test.example.com/signin-oidc"]
logout_urls   = ["https://bct.test.example.com/signout-callback-oidc"]

identity_provider = {
  name = "EntraID"
  type = "OIDC"

  details = {
    client_id                 = "00000000-0000-0000-0000-000000000000"
    client_secret             = "replace-me-from-secrets-manager"
    oidc_issuer               = "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000/v2.0"
    authorize_scopes          = "openid profile email"
    attributes_request_method = "GET"
  }

  attribute_mapping = {
    username = "sub"
    email    = "email"
    name     = "name"
  }
}

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
