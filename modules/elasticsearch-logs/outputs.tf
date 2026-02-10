output "cluster_name" {
  description = "Elasticsearch cluster name"
  value       = "logs"
}

output "cluster_endpoint" {
  description = "Elasticsearch HTTP endpoint"
  value       = "https://logs-es-http.elastic-system.svc:9200"
}

output "secret_name" {
  description = "Secret name containing elastic user password"
  value       = "logs-es-elastic-user"
}
