output "zone_id" {
  description = "Route53 private hosted zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "zone_name" {
  description = "Route53 private hosted zone name"
  value       = aws_route53_zone.private.name
}

output "kibana_fqdn" {
  description = "Fully qualified domain name for Kibana"
  value       = aws_route53_record.kibana.fqdn
}

output "fleet_fqdn" {
  description = "Fully qualified domain name for Fleet Server"
  value       = aws_route53_record.fleet.fqdn
}

output "name_servers" {
  description = "Name servers for the private hosted zone (internal use)"
  value       = aws_route53_zone.private.name_servers
}
