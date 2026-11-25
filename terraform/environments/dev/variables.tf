variable "region" {
  description = "Region the environment is deployed into. No default: it must be supplied explicitly"
  type        = string
}

variable "project" {
  description = "Short project slug used as the resource name prefix. No default: it must be supplied explicitly"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens, start with a letter, and be 2 to 21 characters. It is used to build resource names, several of which have length and character limits."
  }
}

variable "db_master_username" {
  description = "Database master user name. The password is generated and rotated by RDS, never set here"
  type        = string
}
