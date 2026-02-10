# =============================================================================
# VPC Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# =============================================================================
# EKS Outputs
# =============================================================================

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IAM roles"
  value       = module.eks.oidc_issuer_url
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

# =============================================================================
# Elasticsearch Outputs
# =============================================================================

output "elasticsearch_logs_name" {
  description = "Logs Elasticsearch cluster name"
  value       = "logs"
}

output "elasticsearch_logs_endpoint" {
  description = "Logs Elasticsearch internal endpoint"
  value       = "https://logs-es-http.elastic-system.svc:9200"
}

output "elasticsearch_monitoring_name" {
  description = "Monitoring Elasticsearch cluster name"
  value       = var.enable_monitoring_cluster ? "monitoring" : null
}

# =============================================================================
# Kibana Outputs
# =============================================================================

output "kibana_name" {
  description = "Kibana instance name"
  value       = "kibana"
}

output "kibana_endpoint" {
  description = "Kibana internal endpoint"
  value       = "https://kibana-kb-http.elastic-system.svc:5601"
}

# =============================================================================
# Fleet Server Outputs
# =============================================================================

output "fleet_server_name" {
  description = "Fleet Server name"
  value       = "fleet-server"
}

output "fleet_server_endpoint" {
  description = "Fleet Server internal endpoint (private only)"
  value       = "https://fleet-server-agent-http.elastic-system.svc:8220"
}

# =============================================================================
# Jump Box Outputs
# =============================================================================

output "jumpbox_public_ip" {
  description = "Public IP of the Windows jump box"
  value       = var.enable_jumpbox ? module.jumpbox[0].public_ip : null
}

output "jumpbox_instance_id" {
  description = "Instance ID of the Windows jump box"
  value       = var.enable_jumpbox ? module.jumpbox[0].instance_id : null
}

output "jumpbox_private_key" {
  description = "Private key for decrypting Windows password"
  value       = var.enable_jumpbox ? module.jumpbox[0].private_key_pem : null
  sensitive   = true
}

output "jumpbox_password_command" {
  description = "Command to get the Windows password"
  value       = var.enable_jumpbox ? "terraform output -raw jumpbox_private_key > /tmp/jumpbox-key.pem && chmod 600 /tmp/jumpbox-key.pem && aws ec2 get-password-data --instance-id ${module.jumpbox[0].instance_id} --priv-launch-key /tmp/jumpbox-key.pem --query PasswordData --output text --region ${var.region}" : null
}

# =============================================================================
# Access Instructions
# =============================================================================

output "access_instructions" {
  description = "Instructions for accessing the deployment"
  value       = <<-EOT

    === ECK on EKS Reference Implementation ===

    1. Update kubeconfig:
       aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}

    2. Get Elasticsearch password:
       kubectl get secret logs-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d

    3. Port-forward Kibana (from local machine):
       kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601
       Then access: https://localhost:5601

    4. Check cluster health:
       kubectl get elasticsearch,kibana,agent -n elastic-system

    5. View Fleet-enrolled agents in Kibana:
       Navigate to Management > Fleet > Agents

    === Windows Jump Box (RDP Access) ===
    ${var.enable_jumpbox ? "Public IP: Use 'terraform output jumpbox_public_ip'" : "Jump box disabled"}
    ${var.enable_jumpbox ? "Get Windows password: Run the command from 'terraform output jumpbox_password_command'" : ""}
    ${var.enable_jumpbox ? "RDP: Connect to the public IP on port 3389 with username 'Administrator'" : ""}

    === Private DNS Access (from Jump Box) ===
    - Kibana: https://kibana.elastic.internal
    - Monitoring Kibana: https://monitoring.elastic.internal
    - Fleet Server: https://fleet.elastic.internal:8220
    - APM Server: https://apm.elastic.internal:8200

  EOT
}
