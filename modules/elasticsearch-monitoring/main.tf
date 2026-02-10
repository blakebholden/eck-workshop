# Elasticsearch Monitoring Cluster Module
# Separate cluster for stack monitoring metrics and logs

# =============================================================================
# Elasticsearch Monitoring Cluster
# =============================================================================

resource "kubectl_manifest" "elasticsearch_monitoring" {
  yaml_body = <<-YAML
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: monitoring
  namespace: elastic-system
spec:
  version: ${var.elastic_version}

  nodeSets:
  - name: default
    count: 1
    config:
      # Disable memory mapping for containerized environments
      node.store.allow_mmap: false

      # Cluster settings - relaxed for monitoring
      # Note: Do NOT set discovery.type: single-node as it conflicts with ECK's
      # automatic cluster.initial_master_nodes setting
      cluster.routing.allocation.disk.threshold_enabled: true
      cluster.routing.allocation.disk.watermark.low: 90%
      cluster.routing.allocation.disk.watermark.high: 95%
      cluster.routing.allocation.disk.watermark.flood_stage: 98%

      # Node roles
      node.roles:
        - master
        - data
        - data_content
        - data_hot
        - ingest

    podTemplate:
      metadata:
        labels:
          app: elasticsearch
          cluster: monitoring
      spec:
        # Schedule on system nodes (not elastic nodes)
        nodeSelector:
          node-group: system

        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 2Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms1g -Xmx1g"

    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: ${var.storage_size}
        storageClassName: gp3

  # HTTP settings
  http:
    tls:
      selfSignedCertificate:
        disabled: false
        subjectAltNames:
        - dns: monitoring-es-http.elastic-system.svc
        - dns: monitoring-es-http.elastic-system.svc.cluster.local
  YAML

  depends_on = [var.depends_on_operator]
}

# =============================================================================
# Kibana for Monitoring Cluster
# =============================================================================

resource "kubectl_manifest" "kibana_monitoring" {
  yaml_body = <<-YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana-monitoring
  namespace: elastic-system
spec:
  version: ${var.elastic_version}
  count: 1

  elasticsearchRef:
    name: monitoring

  config:
    # Stack monitoring UI settings
    monitoring.ui.ccs.enabled: false
    xpack.monitoring.ui.container.elasticsearch.enabled: true

  podTemplate:
    metadata:
      labels:
        app: kibana
        cluster: monitoring
    spec:
      nodeSelector:
        node-group: system

      containers:
      - name: kibana
        resources:
          requests:
            memory: 1Gi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m

  http:
    tls:
      selfSignedCertificate:
        disabled: false
        subjectAltNames:
        - dns: kibana-monitoring-kb-http.elastic-system.svc
        - dns: kibana-monitoring-kb-http.elastic-system.svc.cluster.local
  YAML

  depends_on = [kubectl_manifest.elasticsearch_monitoring]
}

# =============================================================================
# Variables for module dependencies
# =============================================================================

variable "depends_on_operator" {
  description = "Dependency on ECK operator"
  type        = any
  default     = null
}
