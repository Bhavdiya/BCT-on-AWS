variable "name" {
  description = "The name of the queue. The .fifo suffix is added automatically for FIFO queues"
  type        = string
  default     = "sqs-test-example"
}

variable "fifo_queue" {
  description = "Create a FIFO queue for strict ordering and exactly once processing"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "How long a received message is hidden from other consumers. Set this above the handler's worst case runtime"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "How long an unconsumed message is kept"
  type        = number
  default     = 345600
}

variable "dlq_retention_seconds" {
  description = "How long a poisoned message is kept in the dead letter queue"
  type        = number
  default     = 1209600
}

variable "max_receive_count" {
  description = "Failed deliveries before a message is moved to the dead letter queue"
  type        = number
  default     = 5
}

variable "kms_key_arn" {
  description = "(Optional) CMK for encryption at rest. Null uses SQS managed encryption"
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
