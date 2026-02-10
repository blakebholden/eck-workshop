output "gateway_name" {
  description = "Name of the Gateway resource"
  value       = var.gateway_name
}

output "kibana_hostname" {
  description = "Hostname for Kibana"
  value       = "kibana.${var.domain}"
}

output "fleet_hostname" {
  description = "Hostname for Fleet Server"
  value       = "fleet.${var.domain}"
}

output "domain" {
  description = "Domain used for services"
  value       = var.domain
}

output "lb_hostname" {
  description = "Hostname of the Gateway's load balancer"
  value       = data.external.gateway_lb.result.hostname
}

output "lb_gateway_name" {
  description = "Name of the Gateway resource that owns the LoadBalancer"
  value       = data.external.gateway_lb.result.gateway_name
}

output "lb_programmed" {
  description = "Whether the Gateway is programmed (True/False)"
  value       = data.external.gateway_lb.result.programmed
}
