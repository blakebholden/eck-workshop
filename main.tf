# ECK on EKS Reference Implementation
# Root module orchestrating all components

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = "eck-reference"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Phase 1: AWS Infrastructure
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  cluster_name       = local.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment

  depends_on = [module.vpc]
}

# Windows Jump Box for RDP access to private resources
module "jumpbox" {
  source = "./modules/jumpbox"
  count  = var.enable_jumpbox ? 1 : 0

  cluster_name      = local.cluster_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  instance_type     = var.jumpbox_instance_type
  allowed_rdp_cidrs = var.jumpbox_allowed_cidrs

  # Elastic internal tagging (required for SCP compliance)
  division = var.division
  org      = var.org
  team     = var.team
  project  = var.project

  depends_on = [module.vpc]
}

# =============================================================================
# Phase 2: ECK Operator & Namespaces (parallel with Envoy Gateway)
# =============================================================================

module "eck_operator" {
  source = "./modules/eck-operator"

  eck_operator_version = var.eck_operator_version

  depends_on = [module.eks]
}

# =============================================================================
# Phase 2b: Envoy Gateway Base (PARALLEL - starts LB provisioning early!)
# =============================================================================
# This runs in PARALLEL with ECK Operator, so the NLB starts provisioning
# while Elasticsearch/Kibana/Fleet are deploying. Saves ~3-5 minutes.

module "envoy_gateway_base" {
  source = "./modules/envoy-gateway-base"
  count  = var.enable_gateway_api ? 1 : 0

  domain            = var.internal_domain
  gateway_namespace = "elastic-system"

  depends_on = [module.eks]
}

# =============================================================================
# Phase 3: Elasticsearch Clusters
# =============================================================================

module "elasticsearch_logs" {
  source = "./modules/elasticsearch-logs"

  elastic_version      = var.elastic_version
  node_count           = var.es_logs_node_count
  storage_size         = var.es_logs_storage_size
  enable_trial_license = var.enable_trial_license

  depends_on = [module.eck_operator]
}

module "elasticsearch_monitoring" {
  source = "./modules/elasticsearch-monitoring"
  count  = var.enable_monitoring_cluster ? 1 : 0

  elastic_version   = var.elastic_version
  storage_size      = var.es_monitoring_storage_size
  logs_cluster_name = "logs"

  depends_on = [module.eck_operator]
}

# =============================================================================
# Phase 4: Kibana
# =============================================================================

module "kibana" {
  source = "./modules/kibana"

  elastic_version         = var.elastic_version
  elasticsearch_name      = "logs"
  elasticsearch_namespace = "elastic-system"

  depends_on = [module.elasticsearch_logs]
}

# =============================================================================
# Phase 5: Fleet Configuration (Policies MUST exist before Fleet Server)
# =============================================================================

# Create Fleet policies FIRST - Fleet Server won't start without its policy
module "fleet_config" {
  source = "./modules/fleet-config"

  elasticsearch_name    = "logs"
  kibana_name           = "kibana"
  import_dashboards     = true
  dashboard_ndjson_path = "${path.root}/../kubernetes/kibana-dashboards/app-demo-dashboard.ndjson"

  # Fleet policies MUST be created before Fleet Server starts
  depends_on = [module.kibana]
}

# =============================================================================
# Phase 6: Fleet Server (requires policies to exist)
# =============================================================================

module "fleet_server" {
  source = "./modules/fleet-server"

  elastic_version    = var.elastic_version
  elasticsearch_name = "logs"
  kibana_name        = "kibana"

  depends_on = [module.fleet_config]  # Policies must exist first
}

# =============================================================================
# Phase 7: Elastic Agents (DaemonSet)
# =============================================================================

module "elastic_agents" {
  source = "./modules/elastic-agents"

  elastic_version   = var.elastic_version
  fleet_server_name = "fleet-server"

  # Wait for Fleet Server to be running
  depends_on = [module.fleet_server]
}

# Infrastructure Monitoring Agent
# Sends node/pod metrics to monitoring cluster for visibility when logs cluster is down
module "infra_monitoring_agent" {
  source = "./modules/infra-monitoring-agent"
  count  = var.enable_monitoring_cluster ? 1 : 0

  elastic_version = var.elastic_version

  # Wait for monitoring Elasticsearch to be ready
  depends_on_monitoring = module.elasticsearch_monitoring

  depends_on = [module.elasticsearch_monitoring]
}

# =============================================================================
# Phase 8: APM Server & Logstash
# =============================================================================

module "apm_server" {
  source = "./modules/apm-server"
  count  = var.enable_apm ? 1 : 0

  elastic_version   = var.elastic_version
  kibana_name       = "kibana"
  fleet_server_name = "fleet-server"
  replicas          = var.apm_replicas

  depends_on_fleet = module.fleet_server

  # Wait for Fleet policies to be created before deploying APM server
  depends_on = [module.fleet_config]
}

module "logstash" {
  source = "./modules/logstash"
  count  = var.enable_logstash ? 1 : 0

  elastic_version            = var.elastic_version
  elasticsearch_name         = "logs"
  elasticsearch_cluster_name = "logs"
  replicas                   = var.logstash_replicas

  depends_on_elasticsearch = module.elasticsearch_logs

  depends_on = [module.elasticsearch_logs]
}

# =============================================================================
# Phase 9: Gateway API Routes (connects to pre-provisioned LB)
# =============================================================================

# Gateway routes and backend TLS policies
# The LB was already started by envoy_gateway_base in Phase 2b
module "gateway_api" {
  source = "./modules/gateway-api"
  count  = var.enable_gateway_api ? 1 : 0

  domain            = var.internal_domain
  gateway_name      = module.envoy_gateway_base[0].gateway_name
  gateway_namespace = module.envoy_gateway_base[0].gateway_namespace
  elastic_namespace = "elastic-system"
  enable_monitoring = var.enable_monitoring_cluster

  # Only needs to wait for Kibana/Fleet certs to exist - LB is already provisioning
  depends_on = [module.envoy_gateway_base, module.kibana, module.fleet_server, module.elasticsearch_monitoring]
}

# Route53 Private Hosted Zone for internal DNS
module "route53_private" {
  source = "./modules/route53-private"
  count  = var.enable_gateway_api ? 1 : 0

  domain              = var.internal_domain
  vpc_id              = module.vpc.vpc_id
  gateway_lb_hostname = module.gateway_api[0].lb_hostname
  environment         = var.environment
  create_wildcard     = true

  depends_on = [module.gateway_api]
}

# =============================================================================
# Phase 10: Sample Applications
# =============================================================================

module "sample_apps" {
  source = "./modules/sample-apps"
  count  = var.enable_sample_apps ? 1 : 0

  elastic_version     = var.elastic_version
  enable_sidecar_demo = var.enable_sidecar_demo

  depends_on_fleet_config = module.fleet_config
  depends_on_agents       = module.elastic_agents

  depends_on = [module.fleet_config, module.elastic_agents]
}
