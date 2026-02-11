# AWS Configuration
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "eck-workshop"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = ""
}

# EKS Configuration
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eck-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

# Elastic Stack Configuration
variable "elastic_version" {
  description = "Elastic Stack version"
  type        = string
  default     = "9.3.0"
}

variable "eck_operator_version" {
  description = "ECK operator Helm chart version"
  type        = string
  default     = "3.2.0"
}

# Feature Flags
variable "enable_monitoring_cluster" {
  description = "Deploy separate monitoring Elasticsearch cluster"
  type        = bool
  default     = true
}

variable "enable_sample_apps" {
  description = "Deploy sample applications for demonstration"
  type        = bool
  default     = true
}

variable "enable_sidecar_demo" {
  description = "Enable sidecar demo application"
  type        = bool
  default     = true
}

variable "enable_apm" {
  description = "Deploy APM Server for application performance monitoring"
  type        = bool
  default     = true
}

variable "enable_logstash" {
  description = "Deploy Logstash for data processing pipelines"
  type        = bool
  default     = true
}

variable "enable_jumpbox" {
  description = "Deploy Windows jump box for RDP access to private resources"
  type        = bool
  default     = true
}

variable "enable_gateway_api" {
  description = "Deploy Gateway API with Envoy Gateway and Route53 private DNS"
  type        = bool
  default     = true
}

# Gateway API / Private DNS Configuration
variable "internal_domain" {
  description = "Internal domain for private DNS (e.g., elastic.internal)"
  type        = string
  default     = "elastic.internal"
}

# Jump Box Configuration
variable "jumpbox_instance_type" {
  description = "EC2 instance type for the Windows jump box"
  type        = string
  default     = "t3.medium"
}

variable "jumpbox_allowed_cidrs" {
  description = "CIDR blocks allowed to RDP to the jump box (default: open to all)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Elastic Internal Tagging (required for SCP compliance)
variable "division" {
  description = "Elastic division tag (required)"
  type        = string
  default     = "engineering"
}

variable "org" {
  description = "Elastic org tag (required)"
  type        = string
  default     = "sa"
}

variable "team" {
  description = "Elastic team tag (required)"
  type        = string
  default     = "us-fed-ic"
}

variable "project" {
  description = "Elastic project tag (required)"
  type        = string
  default     = "eck"
}

# APM Server Configuration
variable "apm_replicas" {
  description = "Number of APM Server replicas"
  type        = number
  default     = 1
}

# Logstash Configuration
variable "logstash_replicas" {
  description = "Number of Logstash replicas"
  type        = number
  default     = 1
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC - should be unique per student in shared accounts"
  type        = string
  default     = "10.0.0.0/16"  # Override via TF_VAR_vpc_cidr for unique per-student CIDR
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]  # Reduced for faster deployment
}

# Elasticsearch Configuration
variable "es_logs_storage_size" {
  description = "Storage size for logs Elasticsearch nodes (Gi)"
  type        = string
  default     = "50Gi"
}

variable "es_logs_node_count" {
  description = "Number of nodes in logs Elasticsearch cluster"
  type        = number
  default     = 1  # Single node for dev/demo (non-HA)
}

variable "es_monitoring_storage_size" {
  description = "Storage size for monitoring Elasticsearch node (Gi)"
  type        = string
  default     = "20Gi"
}

variable "enable_trial_license" {
  description = "Enable Elastic Enterprise trial license (30 days)"
  type        = bool
  default     = true
}
