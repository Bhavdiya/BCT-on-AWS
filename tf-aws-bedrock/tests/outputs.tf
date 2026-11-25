output "guardrail_id" {
  description = "The ID of the guardrail"
  value       = module.bedrock.guardrail_id
}

output "guardrail_version" {
  description = "The guardrail version to reference at call time"
  value       = module.bedrock.guardrail_version
}

output "invoke_policy_arn" {
  description = "Attach this policy to the application task role"
  value       = module.bedrock.invoke_policy_arn
}
