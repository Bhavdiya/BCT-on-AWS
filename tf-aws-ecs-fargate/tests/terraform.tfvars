name                       = "ecs-test-example-bct-api"
vpc_id                     = "vpc-00000000000000000"
subnet_ids                 = ["subnet-22222222222222222", "subnet-33333333333333333"]
image                      = "000000000000.dkr.ecr.ap-southeast-1.amazonaws.com/ecr-test-example-bct-api:1.0.0"
execution_role_arn         = "arn:aws:iam::000000000000:role/role-test-example-bct-execution"
task_role_arn              = "arn:aws:iam::000000000000:role/role-test-example-bct-task"
log_group_name             = "/aws/ecs/test-example-bct-api"
ingress_security_group_ids = ["sg-00000000000000000"]
target_group_arn           = "arn:aws:elasticloadbalancing:ap-southeast-1:000000000000:targetgroup/alb-test-example/0000000000000000"

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
