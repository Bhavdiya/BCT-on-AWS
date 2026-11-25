variable "name_prefix" {
  description = "Guardrail and policy name"
  type        = string
}

variable "allowed_model_ids" {
  description = "Foundation model IDs the application may invoke"
  type        = list(string)
  default     = ["anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

variable "allowed_inference_profile_ids" {
  description = "Cross-region inference profile IDs. Newer Anthropic models are only reachable through a profile, not the bare model ID"
  type        = list(string)
  default     = ["us.anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

variable "blocked_message" {
  description = "Response returned when the guardrail blocks a request or completion"
  type        = string
  default     = "This request was blocked by the organisation's AI usage policy."
}

variable "content_filters" {
  description = "Content filter categories enforced on input and output"
  type        = list(string)
  default     = ["SEXUAL", "VIOLENCE", "HATE", "INSULTS", "MISCONDUCT", "PROMPT_ATTACK"]
}

variable "blocked_pii_entities" {
  description = "PII entity types anonymised in prompts and completions"
  type        = list(string)
  default     = ["EMAIL", "PHONE", "CREDIT_DEBIT_CARD_NUMBER"]
}

variable "create_guardrail" {
  description = "Create a Bedrock guardrail. The application must pass its ID on each invoke for it to take effect"
  type        = bool
  default     = true
}
