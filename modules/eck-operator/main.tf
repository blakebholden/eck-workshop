# ECK Operator Module
# Deploys ECK operator via Helm with CRDs

# =============================================================================
# Namespace for Elastic System
# =============================================================================

resource "kubernetes_namespace" "elastic_system" {
  metadata {
    name = "elastic-system"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "elastic.co/managed"           = "true"
    }
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "app_demo" {
  metadata {
    name = "app-demo"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# =============================================================================
# ECK Operator Helm Release
# =============================================================================

resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  version          = var.eck_operator_version
  namespace        = kubernetes_namespace.elastic_system.metadata[0].name
  create_namespace = false

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "webhook.enabled"
    value = "true"
  }

  set {
    name  = "config.validateStorageClass"
    value = "false"
  }

  # Resource limits for operator
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  # Node selector for system nodes
  set {
    name  = "nodeSelector.node-group"
    value = "system"
  }

  # Wait for CRDs to be ready
  wait = true
}

# =============================================================================
# Wait for CRDs to be available
# =============================================================================

resource "time_sleep" "wait_for_crds" {
  depends_on = [helm_release.eck_operator]

  create_duration = "30s"
}
