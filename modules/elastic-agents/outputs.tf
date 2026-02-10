output "agent_name" {
  description = "Elastic Agent DaemonSet name"
  value       = "elastic-agent"
}

output "service_account_name" {
  description = "Elastic Agent service account name"
  value       = kubernetes_service_account.elastic_agent.metadata[0].name
}
