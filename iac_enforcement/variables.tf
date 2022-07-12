variable "logs_retention_days" {
  description = "How long to keep logs"
  type        = number
}

variable "monitored_role" {
  description = "Role to Monitor"
  type        = string
}
