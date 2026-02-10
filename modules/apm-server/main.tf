# APM Server Module
# Deploys APM Server as an Elastic Agent with APM integration
# This enables distributed tracing, application metrics, and error tracking

resource "kubectl_manifest" "apm_server" {
  yaml_body = <<-YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: apm-server
  namespace: ${var.namespace}
spec:
  version: ${var.elastic_version}
  kibanaRef:
    name: ${var.kibana_name}
  fleetServerRef:
    name: ${var.fleet_server_name}
  mode: fleet
  policyID: ${var.apm_policy_id}
  deployment:
    replicas: ${var.replicas}
    podTemplate:
      spec:
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0
        containers:
          - name: agent
            resources:
              requests:
                memory: ${var.memory_request}
                cpu: ${var.cpu_request}
              limits:
                memory: ${var.memory_limit}
                cpu: ${var.cpu_limit}
            ports:
              - containerPort: 8200
                name: apm
                protocol: TCP
  YAML

  depends_on = [var.depends_on_fleet]
}

# Service for APM Server (for external access)
resource "kubectl_manifest" "apm_service" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: apm-server
  namespace: ${var.namespace}
  labels:
    app: apm-server
spec:
  type: ClusterIP
  ports:
    - port: 8200
      targetPort: 8200
      protocol: TCP
      name: apm
  selector:
    agent.k8s.elastic.co/name: apm-server
  YAML

  depends_on = [kubectl_manifest.apm_server]
}
