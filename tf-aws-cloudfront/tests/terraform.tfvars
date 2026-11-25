name                            = "cdn-test-example-bct"
spa_bucket_regional_domain_name = "s3-test-example-bct-spa.s3.ap-southeast-1.amazonaws.com"
api_domain_name                 = "alb-test-example-000000000.ap-southeast-1.elb.amazonaws.com"
certificate_arn                 = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"
aliases                         = ["bct.test.example.com"]

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
