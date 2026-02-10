variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "elasticsearch_name" {
  description = "Name of the Elasticsearch cluster"
  type        = string
  default     = "logs"
}

variable "kibana_name" {
  description = "Name of the Kibana instance"
  type        = string
  default     = "kibana"
}
