name                 = "role-test-example-bct-task"
assume_role_services = ["ecs-tasks.amazonaws.com"]
managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

region                    = "ap-southeast-1"
resource_group_identifier = "APP-1234"

resource_tags = {
  tag_env           = "development"
  tag_business_unit = "finance"
  tag_app_name      = "bct"
  tag_app_owner     = "app.owner@example.com"
}
