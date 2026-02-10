# Sample Apps Module Variables

variable "elastic_version" {
  description = "Elastic Stack version for sidecar agent"
  type        = string
}

variable "enable_sidecar_demo" {
  description = "Enable the sidecar demo application"
  type        = bool
  default     = true
}

variable "depends_on_fleet_config" {
  description = "Dependency on Fleet configuration module"
  type        = any
  default     = null
}

variable "depends_on_agents" {
  description = "Dependency on Elastic Agents module"
  type        = any
  default     = null
}
