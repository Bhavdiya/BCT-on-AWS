output "invoke_policy_arn" {
  description = "Policy attached to the ECS task role"
  value       = aws_iam_policy.invoke.arn
}

output "guardrail_id" {
  description = "Guardrail ID the application passes on each invoke, null when not created"
  value       = try(aws_bedrock_guardrail.this[0].guardrail_id, null)
}

output "guardrail_arn" {
  description = "Guardrail ARN, null when not created"
  value       = try(aws_bedrock_guardrail.this[0].guardrail_arn, null)
}

output "guardrail_version" {
  description = "Guardrail version to reference at call time, null when not created"
  value       = try(aws_bedrock_guardrail.this[0].version, null)
}
