variable "name_prefix" {
  description = "Queue name prefix"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK for encryption at rest"
  type        = string
}

variable "queues" {
  description = "Logical queue names to create. Each gets a matching dead-letter queue"
  type        = list(string)
  default     = ["work"]
}

variable "visibility_timeout_seconds" {
  description = "How long a received message is hidden. Must exceed the handler's worst-case runtime or messages are processed twice"
  type        = number
  default     = 300
}

variable "message_retention_seconds" {
  description = "How long an unconsumed message is retained"
  type        = number
  default     = 345600
}

variable "max_receive_count" {
  description = "Delivery attempts before a message moves to the dead-letter queue"
  type        = number
  default     = 5
}
