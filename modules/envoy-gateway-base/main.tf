# Envoy Gateway Base Module
# Installs Envoy Gateway and creates the Gateway resource early
# This triggers AWS NLB provisioning while Elastic components deploy
#
# OPTIMIZATION: By running this in parallel with ECK/Elasticsearch deployment,
# the NLB is ready by the time we need it, saving ~3-5 minutes

# =============================================================================
# TLS Certificate for Gateway (self-signed, no external dependencies)
# =============================================================================

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "Elastic Internal CA"
    organization = "Elastic"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "gateway" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "gateway" {
  private_key_pem = tls_private_key.gateway.private_key_pem

  subject {
    common_name  = "*.${var.domain}"
    organization = "Elastic"
  }

  dns_names = [
    "*.${var.domain}",
    "kibana.${var.domain}",
    "fleet.${var.domain}",
    "es.${var.domain}",
    "apm.${var.domain}",
    "monitoring.${var.domain}",
  ]
}

resource "tls_locally_signed_cert" "gateway" {
  cert_request_pem   = tls_cert_request.gateway.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

# Create Kubernetes secret with TLS certificate
resource "kubernetes_secret" "gateway_tls" {
  metadata {
    name      = var.tls_secret_name
    namespace = var.gateway_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_locally_signed_cert.gateway.cert_pem
    "tls.key" = tls_private_key.gateway.private_key_pem
    "ca.crt"  = tls_self_signed_cert.ca.cert_pem
  }
}

# =============================================================================
# Envoy Gateway Installation
# =============================================================================

resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = "v1.2.4"
  namespace        = "envoy-gateway-system"
  create_namespace = true

  values = [yamlencode({
    deployment = {
      envoyGateway = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
      }
    }
  })]
}

# =============================================================================
# GatewayClass
# =============================================================================

resource "kubectl_manifest" "gateway_class" {
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy-gateway"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
    }
  })
}

# =============================================================================
# Gateway Resource - THIS TRIGGERS NLB CREATION
# =============================================================================

resource "kubectl_manifest" "elastic_gateway" {
  depends_on = [kubectl_manifest.gateway_class, kubernetes_secret.gateway_tls]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "elastic-gateway"
      namespace = var.gateway_namespace
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
        "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
      }
    }
    spec = {
      gatewayClassName = "envoy-gateway"
      listeners = [
        {
          name     = "https-kibana"
          protocol = "HTTPS"
          port     = 443
          hostname = "kibana.${var.domain}"
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              kind = "Secret"
              name = var.tls_secret_name
            }]
          }
          allowedRoutes = {
            namespaces = { from = "All" }
          }
        },
        {
          name     = "https-monitoring"
          protocol = "HTTPS"
          port     = 443
          hostname = "monitoring.${var.domain}"
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              kind = "Secret"
              name = var.tls_secret_name
            }]
          }
          allowedRoutes = {
            namespaces = { from = "All" }
          }
        },
        {
          name     = "https-fleet"
          protocol = "HTTPS"
          port     = 8220
          hostname = "fleet.${var.domain}"
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              kind = "Secret"
              name = var.tls_secret_name
            }]
          }
          allowedRoutes = {
            namespaces = { from = "All" }
          }
        },
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = { from = "All" }
          }
        }
      ]
    }
  })
}
