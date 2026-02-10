output "agent_name" {
  description = "Name of the infrastructure monitoring agent"
  value       = "elastic-agent-infra"
}

output "service_account_name" {
  description = "Service account used by the agent"
  value       = kubernetes_service_account.infra_agent.metadata[0].name
}
