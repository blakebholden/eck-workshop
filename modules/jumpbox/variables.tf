variable "cluster_name" {
  description = "Name of the EKS cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the jump box will be created"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the jump box"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the jump box"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "allowed_rdp_cidrs" {
  description = "CIDR blocks allowed to RDP to the jump box"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_key_pair" {
  description = "Whether to create a new key pair for the jump box"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Name of existing key pair to use (if create_key_pair is false)"
  type        = string
  default     = ""
}

# Elastic Internal Tagging Requirements
variable "division" {
  description = "Elastic division tag (required for SCP compliance)"
  type        = string
}

variable "org" {
  description = "Elastic org tag (required for SCP compliance)"
  type        = string
}

variable "team" {
  description = "Elastic team tag (required for SCP compliance)"
  type        = string
}

variable "project" {
  description = "Elastic project tag (required for SCP compliance)"
  type        = string
}
