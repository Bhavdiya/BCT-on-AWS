output "guardrail_id" {
  description = "The ID of the guardrail, pass this on every InvokeModel call"
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "The ARN of the guardrail"
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "guardrail_version" {
  description = "The guardrail version to reference at call time"
  value       = aws_bedrock_guardrail.this.version
}

output "invoke_policy_arn" {
  description = "Attach this policy to the application task role"
  value       = aws_iam_policy.invoke.arn
}
