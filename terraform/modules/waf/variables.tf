variable "name_prefix" {
  description = "Web ACL name"
  type        = string
}

variable "scope" {
  description = "CLOUDFRONT or REGIONAL. A CLOUDFRONT ACL must be created by a provider in us-east-1"
  type        = string
  default     = "CLOUDFRONT"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "managed_rule_groups" {
  description = "AWS managed rule groups, evaluated in the order listed"
  type        = list(string)
  default = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet",
    "AWSManagedRulesAmazonIpReputationList",
  ]
}

variable "rate_limit" {
  description = "Requests per five minutes from one IP before it is blocked"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100
    error_message = "WAF rate-based rules require a limit of at least 100."
  }
}

variable "count_only" {
  description = "Run every managed rule in count mode. Use for a soak period before enforcing, to find false positives without breaking traffic"
  type        = bool
  default     = false
}
