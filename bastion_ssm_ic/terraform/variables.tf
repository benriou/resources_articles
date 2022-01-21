variable "automatic_failover" {
  description = ""
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "ec2 instance type (arm based)"
  type        = string
  default     = "t4g.medium"
}


variable "vpc_id" {
  description = ""
  type        = string
  default     = ""
}

variable "vpc_private_subnets_identifier" {
  description = ""
  type        = list(any)
}

variable "dns_zone_id" {
  description = "DNS zone used for record creation CNAME NLB"
  type        = string
}
