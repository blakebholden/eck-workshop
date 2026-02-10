# Infrastructure Monitoring Agent Module
# Deploys a DaemonSet agent that sends node/pod metrics to the MONITORING cluster
# This provides visibility into logs cluster infrastructure even when logs cluster is down

# =============================================================================
# Elastic Agent Service Account (separate from main agent)
# =============================================================================

resource "kubernetes_service_account" "infra_agent" {
  metadata {
    name      = "elastic-agent-infra"
    namespace = "elastic-system"

    labels = {
      "app.kubernetes.io/name"       = "elastic-agent-infra"
      "app.kubernetes.io/component"  = "infrastructure-monitoring"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# =============================================================================
# Elastic Agent ClusterRole (minimal permissions for infrastructure metrics)
# =============================================================================

resource "kubernetes_cluster_role" "infra_agent" {
  metadata {
    name = "elastic-agent-infra"
  }

  # Node metrics and info
  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/stats", "nodes/metrics", "nodes/proxy"]
    verbs      = ["get", "watch", "list"]
  }

  # Pod and namespace info for context
  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces", "services", "events"]
    verbs      = ["get", "watch", "list"]
  }

  # Workload resources for deployment info
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "watch", "list"]
  }

  # Storage info
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "watch", "list"]
  }

  # PV/PVC for storage monitoring
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes", "persistentvolumeclaims"]
    verbs      = ["get", "watch", "list"]
  }

  # Coordination for leader election
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "create", "update"]
  }

  # Non-resource URLs for metrics endpoints
  rule {
    non_resource_urls = ["/metrics", "/healthz", "/healthz/*"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "infra_agent" {
  metadata {
    name = "elastic-agent-infra"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.infra_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.infra_agent.metadata[0].name
    namespace = "elastic-system"
  }
}

# =============================================================================
# Infrastructure Monitoring Agent DaemonSet
# Runs on elastic nodes, sends metrics to monitoring cluster
# =============================================================================

resource "kubectl_manifest" "infra_agent_daemonset" {
  yaml_body = <<-YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: elastic-agent-infra
  namespace: elastic-system
  labels:
    app.kubernetes.io/component: infrastructure-monitoring
spec:
  version: ${var.elastic_version}

  # Connect directly to monitoring Elasticsearch (NOT logs cluster)
  elasticsearchRefs:
  - name: monitoring
    namespace: elastic-system

  # Use standalone mode with system integration
  # This avoids dependency on Fleet Server which is tied to logs cluster
  mode: standalone

  daemonSet:
    podTemplate:
      metadata:
        labels:
          app: elastic-agent-infra
          monitoring-target: infrastructure
      spec:
        serviceAccountName: ${kubernetes_service_account.infra_agent.metadata[0].name}
        automountServiceAccountToken: true

        # Run as root for system-level access to metrics
        securityContext:
          runAsUser: 0

        # Only run on elastic nodes (where logs ES runs)
        nodeSelector:
          node-group: elastic

        # Tolerate the dedicated=elasticsearch taint on elastic node group
        tolerations:
        - key: "dedicated"
          operator: "Equal"
          value: "elasticsearch"
          effect: "NoSchedule"

        containers:
        - name: agent
          resources:
            requests:
              memory: 256Mi
              cpu: 50m
            limits:
              memory: 512Mi
              cpu: 200m

          env:
          # Configure agent to collect system and kubernetes metrics
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName

          # Volume mounts for system metrics
          volumeMounts:
          - name: proc
            mountPath: /hostfs/proc
            readOnly: true
          - name: cgroup
            mountPath: /hostfs/sys/fs/cgroup
            readOnly: true
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
            readOnly: true
          - name: varlog
            mountPath: /var/log
            readOnly: true
          - name: agent-data
            mountPath: /usr/share/elastic-agent/state

        volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: cgroup
          hostPath:
            path: /sys/fs/cgroup
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
        - name: varlog
          hostPath:
            path: /var/log
        - name: agent-data
          emptyDir: {}

        dnsPolicy: ClusterFirstWithHostNet

  # Standalone agent configuration
  config:
    agent:
      monitoring:
        enabled: true
        logs: true
        metrics: true

    inputs:
    # System metrics (CPU, memory, disk, network)
    - type: system/metrics
      id: system-metrics-infra
      data_stream:
        namespace: infrastructure
      use_output: default
      streams:
      - data_stream:
          dataset: system.cpu
          type: metrics
        metricsets: [cpu]
        period: 30s
        cpu.metrics: [percentages, normalized_percentages]
      - data_stream:
          dataset: system.memory
          type: metrics
        metricsets: [memory]
        period: 30s
      - data_stream:
          dataset: system.load
          type: metrics
        metricsets: [load]
        period: 30s
      - data_stream:
          dataset: system.diskio
          type: metrics
        metricsets: [diskio]
        period: 60s
      - data_stream:
          dataset: system.filesystem
          type: metrics
        metricsets: [filesystem]
        period: 60s
        filesystem.ignore_types: [nsfs, squashfs, tmpfs, overlay]
      - data_stream:
          dataset: system.network
          type: metrics
        metricsets: [network]
        period: 30s
      - data_stream:
          dataset: system.process
          type: metrics
        metricsets: [process]
        period: 60s
        process.include_top_n:
          by_cpu: 10
          by_memory: 10

    # Kubernetes node metrics
    - type: kubernetes/metrics
      id: kubernetes-metrics-infra
      data_stream:
        namespace: infrastructure
      use_output: default
      streams:
      - data_stream:
          dataset: kubernetes.node
          type: metrics
        metricsets: [node]
        period: 30s
        add_metadata: true
        hosts: ["https://$${env.NODE_NAME}:10250"]
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        ssl.verification_mode: none
      - data_stream:
          dataset: kubernetes.pod
          type: metrics
        metricsets: [pod]
        period: 30s
        add_metadata: true
        hosts: ["https://$${env.NODE_NAME}:10250"]
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        ssl.verification_mode: none
      - data_stream:
          dataset: kubernetes.container
          type: metrics
        metricsets: [container]
        period: 30s
        add_metadata: true
        hosts: ["https://$${env.NODE_NAME}:10250"]
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        ssl.verification_mode: none
      - data_stream:
          dataset: kubernetes.volume
          type: metrics
        metricsets: [volume]
        period: 60s
        add_metadata: true
        hosts: ["https://$${env.NODE_NAME}:10250"]
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        ssl.verification_mode: none
  YAML

  depends_on = [
    kubernetes_service_account.infra_agent,
    kubernetes_cluster_role_binding.infra_agent,
  ]
}
