variable "name_prefix" {
  description = "Prefix for the key alias"
  type        = string
}

variable "description" {
  description = "What the key protects"
  type        = string
  default     = "Platform data encryption key"
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion completes"
  type        = number
  default     = 30
}
