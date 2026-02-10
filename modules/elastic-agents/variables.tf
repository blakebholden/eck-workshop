variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.2.4"
}

variable "fleet_server_name" {
  description = "Name of the Fleet Server"
  type        = string
  default     = "fleet-server"
}
