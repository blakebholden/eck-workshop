output "logstash_name" {
  description = "Logstash instance name"
  value       = "logstash"
}

output "beats_service_url" {
  description = "Logstash Beats input URL"
  value       = "logstash-ls-beats.${var.namespace}.svc:5044"
}

output "http_service_url" {
  description = "Logstash HTTP input URL"
  value       = "logstash-ls-http.${var.namespace}.svc:8080"
}
