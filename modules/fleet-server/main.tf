# Fleet Server Module
# Deploys Fleet Server as ECK Agent CR - PRIVATE ONLY (no external exposure)

# =============================================================================
# Fleet Server Service Account
# =============================================================================

resource "kubernetes_service_account" "fleet_server" {
  metadata {
    name      = "fleet-server"
    namespace = "elastic-system"

    labels = {
      "app.kubernetes.io/name"       = "fleet-server"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# =============================================================================
# Fleet Server ClusterRole
# =============================================================================

resource "kubernetes_cluster_role" "fleet_server" {
  metadata {
    name = "fleet-server"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces", "nodes"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "create", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "fleet_server" {
  metadata {
    name = "fleet-server"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fleet_server.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fleet_server.metadata[0].name
    namespace = "elastic-system"
  }
}

# =============================================================================
# Fleet Server Agent CR
# =============================================================================

resource "kubectl_manifest" "fleet_server" {
  yaml_body = <<-YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: fleet-server
  namespace: elastic-system
spec:
  version: ${var.elastic_version}
  mode: fleet
  fleetServerEnabled: true

  kibanaRef:
    name: ${var.kibana_name}
    namespace: elastic-system

  elasticsearchRefs:
  - name: ${var.elasticsearch_name}
    namespace: elastic-system

  deployment:
    replicas: 1
    podTemplate:
      metadata:
        labels:
          app: fleet-server
      spec:
        serviceAccountName: ${kubernetes_service_account.fleet_server.metadata[0].name}
        automountServiceAccountToken: true

        nodeSelector:
          node-group: system

        securityContext:
          runAsUser: 0

        containers:
        - name: agent
          resources:
            requests:
              memory: 512Mi
              cpu: 250m
            limits:
              memory: 1Gi
              cpu: 500m

  # HTTP service - ClusterIP only (PRIVATE)
  http:
    service:
      spec:
        type: ClusterIP
    tls:
      selfSignedCertificate:
        disabled: false
        subjectAltNames:
        - dns: fleet-server-agent-http.elastic-system.svc
        - dns: fleet-server-agent-http.elastic-system.svc.cluster.local
        - dns: "*.fleet-server-agent-http.elastic-system.svc"
  YAML

  depends_on = [
    kubernetes_service_account.fleet_server,
    kubernetes_cluster_role_binding.fleet_server,
    var.depends_on_kibana,
  ]
}

# =============================================================================
# Wait for Fleet Server to be ready
# =============================================================================

resource "time_sleep" "wait_for_fleet_server" {
  depends_on = [kubectl_manifest.fleet_server]

  create_duration = "45s"
}

# =============================================================================
# Variables for module dependencies
# =============================================================================

variable "depends_on_kibana" {
  description = "Dependency on Kibana"
  type        = any
  default     = null
}
