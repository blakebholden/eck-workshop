variable "import_dashboards" {
  description = "Import Kibana dashboards"
  type        = bool
  default     = true
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

variable "dashboard_ndjson_path" {
  description = "Path to the dashboard ndjson file to import"
  type        = string
  default     = ""
}
