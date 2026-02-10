# Elastic Agents Module
# Deploys DaemonSet agent for Kubernetes-wide log collection

# =============================================================================
# Elastic Agent Service Account
# =============================================================================

resource "kubernetes_service_account" "elastic_agent" {
  metadata {
    name      = "elastic-agent"
    namespace = "elastic-system"

    labels = {
      "app.kubernetes.io/name"       = "elastic-agent"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# =============================================================================
# Elastic Agent ClusterRole
# =============================================================================

resource "kubernetes_cluster_role" "elastic_agent" {
  metadata {
    name = "elastic-agent"
  }

  # Pod and namespace access for Kubernetes integration
  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "namespaces", "events", "services", "configmaps"]
    verbs      = ["get", "watch", "list"]
  }

  # Node metrics
  rule {
    api_groups = [""]
    resources  = ["nodes/stats", "nodes/metrics"]
    verbs      = ["get"]
  }

  # Apps for deployments, daemonsets, etc.
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "watch", "list"]
  }

  # Batch for jobs
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "watch", "list"]
  }

  # Storage
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "watch", "list"]
  }

  # Coordination for leader election
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "create", "update"]
  }

  # Non-resource URLs for healthchecks
  rule {
    non_resource_urls = ["/metrics", "/healthz", "/healthz/*"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "elastic_agent" {
  metadata {
    name = "elastic-agent"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.elastic_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.elastic_agent.metadata[0].name
    namespace = "elastic-system"
  }
}

# =============================================================================
# Elastic Agent DaemonSet
# =============================================================================

resource "kubectl_manifest" "elastic_agent_daemonset" {
  yaml_body = <<-YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: elastic-agent
  namespace: elastic-system
spec:
  version: ${var.elastic_version}
  mode: fleet
  policyID: kubernetes-policy

  fleetServerRef:
    name: ${var.fleet_server_name}
    namespace: elastic-system

  kibanaRef:
    name: kibana
    namespace: elastic-system

  daemonSet:
    podTemplate:
      metadata:
        labels:
          app: elastic-agent
      spec:
        serviceAccountName: ${kubernetes_service_account.elastic_agent.metadata[0].name}
        automountServiceAccountToken: true

        # Run as root for system-level access
        securityContext:
          runAsUser: 0

        # Tolerate all taints to run on all nodes
        tolerations:
        - operator: Exists

        # Required for kube-proxy metrics (localhost:10249)
        hostNetwork: true

        containers:
        - name: agent
          resources:
            requests:
              memory: 512Mi
              cpu: 100m
            limits:
              memory: 1Gi
              cpu: 500m

          # Volume mounts for log collection
          volumeMounts:
          - name: varlog
            mountPath: /var/log
            readOnly: true
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
            readOnly: true
          - name: varlogpods
            mountPath: /var/log/pods
            readOnly: true

        volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
        - name: varlogpods
          hostPath:
            path: /var/log/pods

        # DNS policy for cluster DNS
        dnsPolicy: ClusterFirstWithHostNet
  YAML

  depends_on = [
    kubernetes_service_account.elastic_agent,
    kubernetes_cluster_role_binding.elastic_agent,
    var.depends_on_fleet_server,
  ]
}

# =============================================================================
# Variables for module dependencies
# =============================================================================

variable "depends_on_fleet_server" {
  description = "Dependency on Fleet Server"
  type        = any
  default     = null
}
