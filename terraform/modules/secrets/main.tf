# Only the container is created here. No secret_version resource exists in this
# module by design: a value passed through Terraform would be written to state
# in plaintext. Values are set with `aws secretsmanager put-secret-value` after
# the first apply, or by a rotation lambda.
resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${var.name_prefix}/${each.key}"
  description             = each.value
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days
}
