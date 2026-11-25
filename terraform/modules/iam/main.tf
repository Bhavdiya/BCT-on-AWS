data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# Execution role: used by the ECS agent, never by the application. It pulls the
# image, creates the log stream, and resolves task-definition secrets.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "execution" {
  name                 = "${var.name_prefix}-ecs-execution"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume.json
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action does not accept a resource restriction
  }

  statement {
    sid = "ECRPull"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [var.ecr_repository_arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${var.log_group_arn}:*"]
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "ReadInjectedSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptInjectedSecrets"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "${var.name_prefix}-ecs-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# ---------------------------------------------------------------------------
# Task role: the application's own identity. This is what replaces Managed
# Identity, so every AWS call the application makes is authorised here.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "task" {
  name                 = "${var.name_prefix}-ecs-task"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume.json
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "task" {
  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "ReadSecrets"
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = var.secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptSecrets"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = var.appconfig_application_arn == null ? [] : [var.appconfig_application_arn]

    content {
      sid = "ReadConfiguration"

      actions = [
        "appconfig:GetLatestConfiguration",
        "appconfig:StartConfigurationSession",
      ]

      resources = ["${statement.value}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_xray ? [1] : []

    content {
      sid = "Tracing"

      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
      ]

      # These four actions are not resource-scopable; X-Ray has no resource ARN
      # for segment ingestion.
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_execute_command ? [1] : []

    content {
      sid = "ExecuteCommandChannel"

      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]

      resources = ["*"]
    }
  }
}

# An empty policy document is invalid, so the inline policy is only attached
# when at least one statement was generated.
locals {
  task_policy_has_statements = length(var.secret_arns) > 0 || var.appconfig_application_arn != null || var.enable_xray || var.enable_execute_command
}

resource "aws_iam_role_policy" "task" {
  count = local.task_policy_has_statements ? 1 : 0

  name   = "${var.name_prefix}-ecs-task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task.json
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  count = var.bedrock_policy_arn == null ? 0 : 1

  role       = aws_iam_role.task.name
  policy_arn = var.bedrock_policy_arn
}
