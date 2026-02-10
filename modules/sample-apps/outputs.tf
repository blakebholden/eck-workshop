# Sample Apps Module Outputs

output "namespace" {
  description = "Namespace where sample apps are deployed"
  value       = local.app_namespace
}

output "demo_apps" {
  description = "List of deployed demo applications"
  value = [
    "demo-stdout",
    "demo-api",
    "demo-worker",
    "demo-webserver",
    var.enable_sidecar_demo ? "demo-sidecar" : null
  ]
}
