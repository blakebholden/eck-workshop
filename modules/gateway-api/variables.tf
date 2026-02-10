variable "domain" {
  description = "Domain for internal services (e.g., elastic.internal)"
  type        = string
  default     = "elastic.internal"
}

variable "gateway_name" {
  description = "Name of the Gateway resource (from envoy-gateway-base)"
  type        = string
  default     = "elastic-gateway"
}

variable "gateway_namespace" {
  description = "Namespace for the Gateway resource"
  type        = string
  default     = "elastic-system"
}

variable "elastic_namespace" {
  description = "Namespace where Elastic services are deployed"
  type        = string
  default     = "elastic-system"
}

variable "enable_monitoring" {
  description = "Whether monitoring Kibana is deployed"
  type        = bool
  default     = true
}
