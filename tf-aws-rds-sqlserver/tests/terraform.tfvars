name                       = "rds-test-example-bct"
vpc_id                     = "vpc-00000000000000000"
subnet_ids                 = ["subnet-22222222222222222", "subnet-33333333333333333"]
allowed_security_group_ids = ["sg-11111111111111111"]
kms_key_arn                = "arn:aws:kms:ap-southeast-1:000000000000:key/00000000-0000-0000-0000-000000000000"
instance_class             = "db.t3.xlarge"

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
