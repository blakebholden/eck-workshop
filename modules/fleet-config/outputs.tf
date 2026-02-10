# Fleet Config Module Outputs

output "fleet_setup_complete" {
  description = "Marker indicating fleet setup job was created"
  value       = kubectl_manifest.fleet_setup.id
}

output "dashboard_import_complete" {
  description = "Marker indicating dashboard import job was created"
  value       = var.import_dashboards ? kubectl_manifest.dashboard_import[0].id : null
}
