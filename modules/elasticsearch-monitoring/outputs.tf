output "cluster_name" {
  description = "Elasticsearch monitoring cluster name"
  value       = "monitoring"
}

output "cluster_endpoint" {
  description = "Elasticsearch HTTP endpoint"
  value       = "https://monitoring-es-http.elastic-system.svc:9200"
}

output "kibana_endpoint" {
  description = "Kibana endpoint for monitoring"
  value       = "https://kibana-monitoring-kb-http.elastic-system.svc:5601"
}
