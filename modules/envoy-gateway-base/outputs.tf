output "gateway_name" {
  description = "Name of the Gateway resource"
  value       = "elastic-gateway"
}

output "gateway_namespace" {
  description = "Namespace of the Gateway"
  value       = var.gateway_namespace
}

output "tls_secret_name" {
  description = "Name of the TLS secret"
  value       = var.tls_secret_name
}

output "ca_cert_pem" {
  description = "CA certificate PEM for trusting the gateway"
  value       = tls_self_signed_cert.ca.cert_pem
  sensitive   = true
}

output "gateway_ready" {
  description = "Marker that Gateway has been created (LB provisioning started)"
  value       = kubectl_manifest.elastic_gateway.id
}
