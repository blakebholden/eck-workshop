variable "domain" {
  description = "Domain name for private hosted zone"
  type        = string
  default     = "elastic.internal"
}

variable "vpc_id" {
  description = "VPC ID to associate with private hosted zone"
  type        = string
}

variable "gateway_lb_hostname" {
  description = "Hostname of the Gateway's load balancer"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "create_es_record" {
  description = "Create DNS record for Elasticsearch"
  type        = bool
  default     = false
}

variable "create_wildcard" {
  description = "Create wildcard DNS record"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
