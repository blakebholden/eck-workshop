output "apm_service_name" {
  description = "APM Server service name"
  value       = "apm-server"
}

output "apm_service_url" {
  description = "APM Server internal URL"
  value       = "http://apm-server.${var.namespace}.svc:8200"
}

output "apm_agent_name" {
  description = "APM Agent CR name"
  value       = "apm-server"
}
