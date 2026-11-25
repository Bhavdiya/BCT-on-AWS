variable "name" {
  description = "Name of the guardrail and the generated invoke policy"
  type        = string
  default     = "bedrock-test-example"
}

variable "allowed_model_ids" {
  description = "Foundation models the application may invoke"
  type        = list(string)
  default     = ["anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

variable "allowed_inference_profile_ids" {
  description = "Cross region inference profiles the application may invoke. Most regions require these rather than the bare model ID"
  type        = list(string)
  default     = ["apac.anthropic.claude-sonnet-4-5-20250929-v1:0"]
}

variable "blocked_message" {
  description = "What the caller sees when the guardrail blocks a request or a response"
  type        = string
  default     = "This request was blocked by the organisation's AI usage policy."
}

variable "content_filters" {
  description = "Bedrock content filter categories to enforce on both input and output"
  type        = list(string)
  default     = ["SEXUAL", "VIOLENCE", "HATE", "INSULTS", "MISCONDUCT", "PROMPT_ATTACK"]
}

variable "blocked_pii_entities" {
  description = "PII entity types to strip from prompts and completions"
  type        = list(string)
  default     = ["EMAIL", "PHONE", "NAME", "CREDIT_DEBIT_CARD_NUMBER"]
}

variable "region" {
  description = "The AWS region where the resource will be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "resource_group_identifier" {
  description = "The AppRef or resource group identifier"
  type        = string
  default     = "APP-1234"
}

variable "resource_tags" {
  type = object({
    tag_env           = string
    tag_business_unit = string
    tag_app_name      = string
    tag_app_owner     = string
  })
  description = "(Required) Standard Tags to Apply"
}

variable "additional_tags" {
  type        = map(string)
  description = "(Optional) Additional tags to apply"
  default     = {}
}
