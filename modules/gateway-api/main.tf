# Gateway API Routes Module
# Creates HTTPRoutes and BackendTLSPolicies after Kibana/Fleet are ready
# The base Gateway and LB are created earlier by envoy-gateway-base module

# =============================================================================
# HTTPRoutes - Connect Gateway listeners to backend services
# =============================================================================

# HTTPRoute for Kibana
resource "kubectl_manifest" "kibana_route" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "kibana-route"
      namespace = var.elastic_namespace
    }
    spec = {
      parentRefs = [{
        name      = var.gateway_name
        namespace = var.gateway_namespace
      }]
      hostnames = ["kibana.${var.domain}"]
      rules = [{
        backendRefs = [{
          name = "kibana-kb-http"
          port = 5601
        }]
      }]
    }
  })
}

# HTTPRoute for Monitoring Kibana
resource "kubectl_manifest" "monitoring_kibana_route" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "monitoring-kibana-route"
      namespace = var.elastic_namespace
    }
    spec = {
      parentRefs = [{
        name      = var.gateway_name
        namespace = var.gateway_namespace
        port      = 443
      }]
      hostnames = ["monitoring.${var.domain}"]
      rules = [{
        backendRefs = [{
          name = "kibana-monitoring-kb-http"
          port = 5601
        }]
      }]
    }
  })
}

# HTTPRoute for Fleet Server
resource "kubectl_manifest" "fleet_route" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "fleet-route"
      namespace = var.elastic_namespace
    }
    spec = {
      parentRefs = [{
        name      = var.gateway_name
        namespace = var.gateway_namespace
        port      = 8220
      }]
      hostnames = ["fleet.${var.domain}"]
      rules = [{
        backendRefs = [{
          name = "fleet-server-agent-http"
          port = 8220
        }]
      }]
    }
  })
}

# =============================================================================
# Backend TLS Configuration for ECK Services
# =============================================================================

# Get Kibana CA certificate from ECK-generated secret
data "kubernetes_secret" "kibana_certs" {
  metadata {
    name      = "kibana-kb-http-certs-public"
    namespace = var.elastic_namespace
  }
}

# Get Monitoring Kibana CA certificate
data "kubernetes_secret" "monitoring_kibana_certs" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name      = "kibana-monitoring-kb-http-certs-public"
    namespace = var.elastic_namespace
  }
}

# Get Fleet Server CA certificate from ECK-generated secret
data "kubernetes_secret" "fleet_certs" {
  metadata {
    name      = "fleet-server-agent-http-certs-public"
    namespace = var.elastic_namespace
  }
}

# Create ConfigMap with Kibana CA for BackendTLSPolicy
resource "kubernetes_config_map" "kibana_ca" {
  metadata {
    name      = "kibana-ca-cert"
    namespace = var.elastic_namespace
  }

  data = {
    "ca.crt" = data.kubernetes_secret.kibana_certs.data["ca.crt"]
  }
}

# Create ConfigMap with Monitoring Kibana CA
resource "kubernetes_config_map" "monitoring_kibana_ca" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name      = "monitoring-kibana-ca-cert"
    namespace = var.elastic_namespace
  }

  data = {
    "ca.crt" = data.kubernetes_secret.monitoring_kibana_certs[0].data["ca.crt"]
  }
}

# Create ConfigMap with Fleet Server CA for BackendTLSPolicy
resource "kubernetes_config_map" "fleet_ca" {
  metadata {
    name      = "fleet-ca-cert"
    namespace = var.elastic_namespace
  }

  data = {
    "ca.crt" = data.kubernetes_secret.fleet_certs.data["ca.crt"]
  }
}

# BackendTLSPolicy for Kibana
resource "kubectl_manifest" "kibana_backend_tls" {
  depends_on = [
    kubectl_manifest.kibana_route,
    kubernetes_config_map.kibana_ca
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1alpha3"
    kind       = "BackendTLSPolicy"
    metadata = {
      name      = "kibana-backend-tls"
      namespace = var.elastic_namespace
    }
    spec = {
      targetRefs = [{
        group = ""
        kind  = "Service"
        name  = "kibana-kb-http"
      }]
      validation = {
        caCertificateRefs = [{
          group = ""
          kind  = "ConfigMap"
          name  = "kibana-ca-cert"
        }]
        hostname = "kibana-kb-http.${var.elastic_namespace}.svc"
      }
    }
  })
}

# BackendTLSPolicy for Monitoring Kibana
resource "kubectl_manifest" "monitoring_kibana_backend_tls" {
  count = var.enable_monitoring ? 1 : 0
  depends_on = [
    kubectl_manifest.monitoring_kibana_route,
    kubernetes_config_map.monitoring_kibana_ca
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1alpha3"
    kind       = "BackendTLSPolicy"
    metadata = {
      name      = "monitoring-kibana-backend-tls"
      namespace = var.elastic_namespace
    }
    spec = {
      targetRefs = [{
        group = ""
        kind  = "Service"
        name  = "kibana-monitoring-kb-http"
      }]
      validation = {
        caCertificateRefs = [{
          group = ""
          kind  = "ConfigMap"
          name  = "monitoring-kibana-ca-cert"
        }]
        hostname = "kibana-monitoring-kb-http.${var.elastic_namespace}.svc"
      }
    }
  })
}

# BackendTLSPolicy for Fleet Server
resource "kubectl_manifest" "fleet_backend_tls" {
  depends_on = [
    kubectl_manifest.fleet_route,
    kubernetes_config_map.fleet_ca
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1alpha3"
    kind       = "BackendTLSPolicy"
    metadata = {
      name      = "fleet-backend-tls"
      namespace = var.elastic_namespace
    }
    spec = {
      targetRefs = [{
        group = ""
        kind  = "Service"
        name  = "fleet-server-agent-http"
      }]
      validation = {
        caCertificateRefs = [{
          group = ""
          kind  = "ConfigMap"
          name  = "fleet-ca-cert"
        }]
        hostname = "fleet-server-agent-http.${var.elastic_namespace}.svc"
      }
    }
  })
}

# =============================================================================
# Get LoadBalancer hostname (should already be provisioned by now)
# =============================================================================

# Wait for LB - increased to ensure NLB is fully provisioned
resource "time_sleep" "wait_for_lb" {
  depends_on = [
    kubectl_manifest.kibana_backend_tls,
    kubectl_manifest.fleet_backend_tls
  ]

  # NLB typically takes 2-3 minutes to provision
  # With early start from envoy-gateway-base, 60s should be sufficient
  create_duration = "60s"
}

# Get the LoadBalancer hostname from the Gateway resource directly
# Simple single query - no retry loop needed, Gateway should be ready by now
data "external" "gateway_lb" {
  depends_on = [time_sleep.wait_for_lb]

  program = ["bash", "-c", <<-EOF
    export KUBECONFIG="$${HOME}/.kube/config"

    HOSTNAME=$(kubectl get gateway "${var.gateway_name}" -n "${var.gateway_namespace}" \
      -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)

    if [ -z "$HOSTNAME" ] || [ "$HOSTNAME" = "null" ]; then
      echo "ERROR: Gateway LB not ready. Run: kubectl get gateway -n ${var.gateway_namespace}" >&2
      exit 1
    fi

    echo "{\"hostname\": \"$HOSTNAME\", \"gateway_name\": \"${var.gateway_name}\", \"programmed\": \"True\"}"
  EOF
  ]
}
