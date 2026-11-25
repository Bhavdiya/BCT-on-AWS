name            = "alb-test-example"
vpc_id          = "vpc-00000000000000000"
subnet_ids      = ["subnet-00000000000000000", "subnet-11111111111111111"]
certificate_arn = "arn:aws:acm:ap-southeast-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"
target_port     = 8080

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
