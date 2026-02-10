variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "node_count" {
  description = "Number of Elasticsearch nodes"
  type        = number
  default     = 3
}

variable "storage_size" {
  description = "Storage size per node"
  type        = string
  default     = "50Gi"
}

variable "enable_trial_license" {
  description = "Enable Elastic Enterprise trial license"
  type        = bool
  default     = true
}

variable "depends_on_operator" {
  description = "Dependency on ECK operator"
  type        = any
  default     = null
}
