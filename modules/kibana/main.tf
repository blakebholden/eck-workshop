# Kibana Module
# Main Kibana instance connected to logs Elasticsearch cluster

# =============================================================================
# Kibana Instance
# =============================================================================

resource "kubectl_manifest" "kibana" {
  yaml_body = <<-YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: elastic-system
spec:
  version: ${var.elastic_version}
  count: 1

  elasticsearchRef:
    name: ${var.elasticsearch_name}
    namespace: ${var.elasticsearch_namespace}

  config:
    # Server settings
    server.publicBaseUrl: "https://kibana.example.com"

    # Default to Observability solution view with dark mode
    uiSettings.overrides:
      "theme:darkMode": true
      defaultRoute: "/app/observability/overview"

    # Fleet settings
    xpack.fleet.enabled: true
    xpack.fleet.agents.enabled: true
    xpack.fleet.agents.elasticsearch.hosts:
      - "https://${var.elasticsearch_name}-es-http.${var.elasticsearch_namespace}.svc:9200"
    xpack.fleet.agents.fleet_server.hosts:
      - "https://fleet-server-agent-http.elastic-system.svc:8220"

    # Encryption keys (should be overridden in production)
    xpack.encryptedSavedObjects.encryptionKey: "minimum-32-character-encryption-key!"
    xpack.reporting.encryptionKey: "minimum-32-character-reporting-key!!"
    xpack.security.encryptionKey: "minimum-32-character-security-key!!!"

    # Monitoring UI
    monitoring.ui.ccs.enabled: false
    xpack.monitoring.ui.container.elasticsearch.enabled: true

    # Spaces and RBAC ready
    xpack.spaces.enabled: true

  podTemplate:
    metadata:
      labels:
        app: kibana
        cluster: logs
    spec:
      nodeSelector:
        node-group: system

      containers:
      - name: kibana
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1
        readinessProbe:
          httpGet:
            path: /api/status
            port: 5601
            scheme: HTTPS
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 10

  http:
    tls:
      selfSignedCertificate:
        disabled: false
        subjectAltNames:
        - dns: kibana-kb-http.elastic-system.svc
        - dns: kibana-kb-http.elastic-system.svc.cluster.local
        - dns: kibana.example.com
  YAML

  depends_on = [var.depends_on_elasticsearch]
}

# =============================================================================
# Wait for Kibana to be ready
# =============================================================================

resource "time_sleep" "wait_for_kibana" {
  depends_on = [kubectl_manifest.kibana]

  create_duration = "45s"
}

# =============================================================================
# Variables for module dependencies
# =============================================================================

variable "depends_on_elasticsearch" {
  description = "Dependency on Elasticsearch"
  type        = any
  default     = null
}
