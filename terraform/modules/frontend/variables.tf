variable "name_prefix" {
  description = "Prefix for the bucket name"
  type        = string
}

variable "kms_key_arn" {
  description = "(Optional) CMK for object encryption. Null uses SSE-S3, which is what CloudFront OAC supports without extra key policy work"
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Days a superseded object version is retained, giving a rollback window for a bad front-end release"
  type        = number
  default     = 30
}
