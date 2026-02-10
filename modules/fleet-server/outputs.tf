output "fleet_server_name" {
  description = "Fleet Server name"
  value       = "fleet-server"
}

output "fleet_server_endpoint" {
  description = "Fleet Server internal endpoint (ClusterIP - private only)"
  value       = "https://fleet-server-agent-http.elastic-system.svc:8220"
}

output "service_account_name" {
  description = "Fleet Server service account name"
  value       = kubernetes_service_account.fleet_server.metadata[0].name
}
