variable "name" {
  description = "The name of the Web ACL"
  type        = string
  default     = "waf-test-example"
}

variable "scope" {
  description = "REGIONAL for an ALB or API Gateway, CLOUDFRONT for a distribution. CLOUDFRONT requires the provider be pinned to us-east-1"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "managed_rule_groups" {
  description = "AWS managed rule groups to run, in the order given"
  type        = list(string)
  default = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet",
    "AWSManagedRulesAmazonIpReputationList",
  ]
}

variable "rate_limit" {
  description = "Requests per five minutes from a single IP before it is blocked"
  type        = number
  default     = 2000
}

variable "log_destination_arn" {
  description = "(Optional) Log group, firehose or bucket ARN to send WAF logs to. The log group name must start with aws-waf-logs-"
  type        = string
  default     = null
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
