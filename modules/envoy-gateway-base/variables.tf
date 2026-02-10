variable "domain" {
  description = "Internal domain for services (e.g., elastic.internal)"
  type        = string
}

variable "gateway_namespace" {
  description = "Namespace for the Gateway resource"
  type        = string
  default     = "elastic-system"
}

variable "tls_secret_name" {
  description = "Name of the TLS secret for Gateway"
  type        = string
  default     = "elastic-gateway-tls"
}
