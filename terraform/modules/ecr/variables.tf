variable "name_prefix" {
  description = "Repository name"
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE stops a released tag being overwritten in place"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "kms_key_arn" {
  description = "CMK to encrypt image layers with"
  type        = string
}

variable "max_image_count" {
  description = "Tagged images retained before the oldest expire"
  type        = number
  default     = 30
}

variable "untagged_expiry_days" {
  description = "Days before an untagged layer is expired"
  type        = number
  default     = 7
}
