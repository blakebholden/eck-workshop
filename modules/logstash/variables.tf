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

variable "elasticsearch_name" {
  description = "Name of the Elasticsearch cluster to connect to"
  type        = string
  default     = "logs"
}

variable "elasticsearch_cluster_name" {
  description = "Cluster name alias for Elasticsearch"
  type        = string
  default     = "logs"
}

variable "replicas" {
  description = "Number of Logstash replicas"
  type        = number
  default     = 1
}

variable "memory_request" {
  description = "Memory request for Logstash"
  type        = string
  default     = "1Gi"
}

variable "memory_limit" {
  description = "Memory limit for Logstash"
  type        = string
  default     = "2Gi"
}

variable "cpu_request" {
  description = "CPU request for Logstash"
  type        = string
  default     = "500m"
}

variable "cpu_limit" {
  description = "CPU limit for Logstash"
  type        = string
  default     = "1000m"
}

variable "depends_on_elasticsearch" {
  description = "Dependency on Elasticsearch being ready"
  type        = any
  default     = null
}
