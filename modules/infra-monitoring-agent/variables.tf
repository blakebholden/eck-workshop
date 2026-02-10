variable "elastic_version" {
  description = "Elastic Stack version for the agent"
  type        = string
}

variable "depends_on_monitoring" {
  description = "Dependency on monitoring Elasticsearch cluster"
  type        = any
  default     = null
}
