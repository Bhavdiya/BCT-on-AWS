name                       = "search-test-example-bct"
vpc_id                     = "vpc-00000000000000000"
subnet_ids                 = ["subnet-22222222222222222", "subnet-33333333333333333"]
allowed_security_group_ids = ["sg-11111111111111111"]
master_user_arn            = "arn:aws:iam::000000000000:role/role-test-example-bct-task"
instance_type              = "r7g.large.search"

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
