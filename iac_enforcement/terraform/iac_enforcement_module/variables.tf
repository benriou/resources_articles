variable "logs_retention_days" {
  description = "How long to keep logs"
  type        = number
}

variable "monitored_role" {
  description = "Role to Monitor"
  type        = string
}

variable "sns_email_subscription" {
  description = "Destination Emails for SNS topic"
  type        = string
}
