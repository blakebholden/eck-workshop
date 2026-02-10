variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "storage_size" {
  description = "Storage size for monitoring cluster"
  type        = string
  default     = "20Gi"
}

variable "logs_cluster_name" {
  description = "Name of the logs cluster to monitor"
  type        = string
  default     = "logs"
}
