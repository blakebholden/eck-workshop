output "operator_namespace" {
  description = "Namespace where ECK operator is deployed"
  value       = kubernetes_namespace.elastic_system.metadata[0].name
}

output "operator_version" {
  description = "ECK operator version"
  value       = var.eck_operator_version
}

output "namespaces" {
  description = "Created namespaces"
  value = {
    elastic_system = kubernetes_namespace.elastic_system.metadata[0].name
    logging        = kubernetes_namespace.logging.metadata[0].name
    monitoring     = kubernetes_namespace.monitoring.metadata[0].name
    app_demo       = kubernetes_namespace.app_demo.metadata[0].name
  }
}
