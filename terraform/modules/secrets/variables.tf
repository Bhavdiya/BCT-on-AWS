variable "name_prefix" {
  description = "Prefix for every secret name"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK the secrets are encrypted with"
  type        = string
}

variable "secrets" {
  description = "Secrets to create, keyed by short name. Values are never set here, they are populated out of band after the first apply"
  type        = map(string)
  default     = {}
}

variable "recovery_window_in_days" {
  description = "How long a deleted secret can be recovered. 0 deletes immediately, appropriate only for ephemeral environments"
  type        = number
  default     = 30
}
