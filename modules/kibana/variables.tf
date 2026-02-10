variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "elasticsearch_name" {
  description = "Name of the Elasticsearch cluster to connect to"
  type        = string
  default     = "logs"
}

variable "elasticsearch_namespace" {
  description = "Namespace of the Elasticsearch cluster"
  type        = string
  default     = "elastic-system"
}
