output "kibana_name" {
  description = "Kibana instance name"
  value       = "kibana"
}

output "kibana_endpoint" {
  description = "Kibana HTTP endpoint"
  value       = "https://kibana-kb-http.elastic-system.svc:5601"
}

output "kibana_secret_name" {
  description = "Secret name for Kibana service account"
  value       = "kibana-kb-es-user"
}
