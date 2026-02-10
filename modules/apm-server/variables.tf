variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "elastic-system"
}

variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "kibana_name" {
  description = "Name of the Kibana instance to connect to"
  type        = string
  default     = "kibana"
}

variable "fleet_server_name" {
  description = "Name of the Fleet Server to connect to"
  type        = string
  default     = "fleet-server"
}

variable "apm_policy_id" {
  description = "Fleet policy ID for APM Server"
  type        = string
  default     = "apm-server-policy"
}

variable "replicas" {
  description = "Number of APM Server replicas"
  type        = number
  default     = 1
}

variable "memory_request" {
  description = "Memory request for APM Server"
  type        = string
  default     = "512Mi"
}

variable "memory_limit" {
  description = "Memory limit for APM Server"
  type        = string
  default     = "1Gi"
}

variable "cpu_request" {
  description = "CPU request for APM Server"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit for APM Server"
  type        = string
  default     = "500m"
}

variable "depends_on_fleet" {
  description = "Dependency on Fleet Server being ready"
  type        = any
  default     = null
}
