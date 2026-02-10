# Sample Applications Module
# Deploys demo applications to demonstrate log collection patterns

# =============================================================================
# Namespace (created by eck-operator module, we just reference it)
# =============================================================================

data "kubernetes_namespace" "app_demo" {
  metadata {
    name = "app-demo"
  }
}

locals {
  app_namespace = data.kubernetes_namespace.app_demo.metadata[0].name
}

# =============================================================================
# Copy secrets needed by sidecar agent
# =============================================================================

# Copy ES CA cert to app-demo namespace for sidecar agent
data "kubernetes_secret" "es_ca" {
  metadata {
    name      = "logs-es-http-certs-public"
    namespace = "elastic-system"
  }
}

resource "kubernetes_secret" "es_ca_app_demo" {
  metadata {
    name      = "logs-es-http-certs-public"
    namespace = local.app_namespace
  }

  data = data.kubernetes_secret.es_ca.data
}

# =============================================================================
# Sidecar Agent RBAC
# =============================================================================

resource "kubernetes_service_account" "elastic_agent_sidecar" {
  metadata {
    name      = "elastic-agent-sidecar"
    namespace = local.app_namespace

    labels = {
      "app.kubernetes.io/name"       = "elastic-agent-sidecar"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_role" "elastic_agent_sidecar" {
  metadata {
    name      = "elastic-agent-sidecar"
    namespace = local.app_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "create", "update"]
  }
}

resource "kubernetes_role_binding" "elastic_agent_sidecar" {
  metadata {
    name      = "elastic-agent-sidecar"
    namespace = local.app_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.elastic_agent_sidecar.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.elastic_agent_sidecar.metadata[0].name
    namespace = local.app_namespace
  }
}

# =============================================================================
# Demo Stdout Application (DaemonSet collection)
# =============================================================================

resource "kubernetes_deployment" "demo_stdout" {
  metadata {
    name      = "demo-stdout"
    namespace = local.app_namespace

    labels = {
      app            = "demo-stdout"
      log-collection = "daemonset"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "demo-stdout"
      }
    }

    template {
      metadata {
        labels = {
          app            = "demo-stdout"
          log-collection = "daemonset"
        }
      }

      spec {
        node_selector = {
          "node-group" = "apps"
        }

        container {
          name  = "logger"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c", <<-EOF
            echo "Starting demo-stdout application"
            i=0
            while true; do
              i=$((i+1))
              timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
              echo "{\"timestamp\":\"$timestamp\",\"level\":\"INFO\",\"message\":\"Processing request $i\",\"app\":\"demo-stdout\",\"type\":\"request\"}"
              if [ $((i % 10)) -eq 0 ]; then
                echo "{\"timestamp\":\"$timestamp\",\"level\":\"WARN\",\"message\":\"High latency detected on request $i\",\"app\":\"demo-stdout\",\"latency_ms\":1500}"
              fi
              if [ $((i % 25)) -eq 0 ]; then
                echo "{\"timestamp\":\"$timestamp\",\"level\":\"ERROR\",\"message\":\"Failed to process request $i\",\"app\":\"demo-stdout\",\"error\":\"Connection timeout\"}" >&2
              fi
              sleep 5
            done
          EOF
          ]

          resources {
            requests = {
              memory = "32Mi"
              cpu    = "10m"
            }
            limits = {
              memory = "64Mi"
              cpu    = "50m"
            }
          }
        }
      }
    }
  }
}

# =============================================================================
# Demo API Application (DaemonSet collection)
# =============================================================================

resource "kubernetes_deployment" "demo_api" {
  metadata {
    name      = "demo-api"
    namespace = local.app_namespace

    labels = {
      app  = "demo-api"
      tier = "backend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "demo-api"
      }
    }

    template {
      metadata {
        labels = {
          app            = "demo-api"
          tier           = "backend"
          log-collection = "daemonset"
        }
      }

      spec {
        node_selector = {
          "node-group" = "apps"
        }

        container {
          name  = "api"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c", <<-EOF
            echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"INFO","service":"demo-api","message":"Application starting","version":"1.0.0"}'
            request_id=0
            while true; do
              request_id=$((request_id+1))
              timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
              trace_id=$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')
              rand=$((RANDOM % 100))
              if [ $rand -lt 60 ]; then
                duration=$((50 + RANDOM % 150))
                echo '{"timestamp":"'$timestamp'","level":"INFO","service":"demo-api","trace_id":"'$trace_id'","request_id":'$request_id',"message":"Request processed successfully","method":"GET","path":"/api/data","status":200,"duration_ms":'$duration'}'
              elif [ $rand -lt 75 ]; then
                duration=$((500 + RANDOM % 1500))
                echo '{"timestamp":"'$timestamp'","level":"WARN","service":"demo-api","trace_id":"'$trace_id'","request_id":'$request_id',"message":"Slow request detected","method":"GET","path":"/api/data","status":200,"duration_ms":'$duration'}'
              elif [ $rand -lt 93 ]; then
                echo '{"timestamp":"'$timestamp'","level":"WARN","service":"demo-api","trace_id":"'$trace_id'","request_id":'$request_id',"message":"Invalid request parameters","method":"POST","path":"/api/users","status":400,"error":"validation_failed"}'
              else
                echo '{"timestamp":"'$timestamp'","level":"ERROR","service":"demo-api","trace_id":"'$trace_id'","request_id":'$request_id',"message":"Internal server error","method":"POST","path":"/api/orders","status":500,"error":"database_error"}'
              fi
              sleep 2
            done
          EOF
          ]

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}

# =============================================================================
# Demo Worker Application (DaemonSet collection)
# =============================================================================

resource "kubernetes_deployment" "demo_worker" {
  metadata {
    name      = "demo-worker"
    namespace = local.app_namespace

    labels = {
      app  = "demo-worker"
      tier = "worker"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "demo-worker"
      }
    }

    template {
      metadata {
        labels = {
          app            = "demo-worker"
          tier           = "worker"
          log-collection = "daemonset"
        }
      }

      spec {
        node_selector = {
          "node-group" = "apps"
        }

        container {
          name  = "worker"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c", <<-EOF
            echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"INFO","service":"demo-worker","message":"Worker started","worker_id":"worker-1","queue":"jobs"}'
            job_id=0
            while true; do
              job_id=$((job_id+1))
              timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
              echo '{"timestamp":"'$timestamp'","level":"INFO","service":"demo-worker","job_id":'$job_id',"message":"Processing job","job_type":"data_sync","status":"started"}'
              rand=$((RANDOM % 100))
              if [ $rand -lt 70 ]; then
                sleep 1
                echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"INFO","service":"demo-worker","job_id":'$job_id',"message":"Job completed successfully","status":"completed","duration_ms":1000}'
              elif [ $rand -lt 95 ]; then
                sleep 2
                echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"INFO","service":"demo-worker","job_id":'$job_id',"message":"Job completed","status":"completed","duration_ms":2000}'
              else
                echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"ERROR","service":"demo-worker","job_id":'$job_id',"message":"Job failed","status":"failed","error":"Connection refused"}'
              fi
              sleep 3
            done
          EOF
          ]

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}

# =============================================================================
# Demo Webserver Application (DaemonSet collection)
# =============================================================================

resource "kubernetes_config_map" "demo_webserver" {
  metadata {
    name      = "demo-webserver-config"
    namespace = local.app_namespace
  }

  data = {
    "nginx.conf" = <<-EOF
      worker_processes 1;
      error_log /dev/stderr warn;

      events {
          worker_connections 1024;
      }

      http {
          log_format json_combined escape=json '{'
            '"timestamp":"$time_iso8601",'
            '"remote_addr":"$remote_addr",'
            '"method":"$request_method",'
            '"uri":"$uri",'
            '"status":$status,'
            '"body_bytes_sent":$body_bytes_sent,'
            '"request_time":$request_time,'
            '"http_user_agent":"$http_user_agent"'
          '}';

          access_log /dev/stdout json_combined;

          server {
              listen 80;
              server_name _;

              location /health {
                  return 200 '{"status":"healthy"}';
                  add_header Content-Type application/json;
              }

              location /api/users {
                  return 200 '{"users":[{"id":1,"name":"Alice"}]}';
                  add_header Content-Type application/json;
              }

              location /api/error {
                  return 500 '{"error":"Internal server error"}';
                  add_header Content-Type application/json;
              }

              location / {
                  return 404 '{"error":"Not found"}';
                  add_header Content-Type application/json;
              }
          }
      }
    EOF
  }
}

resource "kubernetes_deployment" "demo_webserver" {
  metadata {
    name      = "demo-webserver"
    namespace = local.app_namespace

    labels = {
      app  = "demo-webserver"
      tier = "frontend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "demo-webserver"
      }
    }

    template {
      metadata {
        labels = {
          app            = "demo-webserver"
          tier           = "frontend"
          log-collection = "daemonset"
        }
      }

      spec {
        node_selector = {
          "node-group" = "apps"
        }

        container {
          name  = "nginx"
          image = "nginx:1.25-alpine"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }

        container {
          name  = "traffic-generator"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c", <<-EOF
            i=0
            while true; do
              i=$((i+1))
              wget -q -O /dev/null http://localhost/health 2>/dev/null
              wget -q -O /dev/null http://localhost/api/users 2>/dev/null
              if [ $((i % 5)) -eq 0 ]; then
                wget -q -O /dev/null http://localhost/missing 2>/dev/null
              fi
              if [ $((i % 10)) -eq 0 ]; then
                wget -q -O /dev/null http://localhost/api/error 2>/dev/null
              fi
              sleep 2
            done
          EOF
          ]

          resources {
            requests = {
              memory = "16Mi"
              cpu    = "10m"
            }
            limits = {
              memory = "32Mi"
              cpu    = "50m"
            }
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.demo_webserver.metadata[0].name
          }
        }
      }
    }
  }
}

# =============================================================================
# Demo Sidecar Application (Sidecar collection)
# =============================================================================

resource "kubernetes_deployment" "demo_sidecar" {
  count = var.enable_sidecar_demo ? 1 : 0

  metadata {
    name      = "demo-sidecar"
    namespace = local.app_namespace

    labels = {
      app            = "demo-sidecar"
      log-collection = "sidecar"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "demo-sidecar"
      }
    }

    template {
      metadata {
        labels = {
          app            = "demo-sidecar"
          log-collection = "sidecar"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.elastic_agent_sidecar.metadata[0].name

        node_selector = {
          "node-group" = "apps"
        }

        # Main application container
        container {
          name  = "app"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c", <<-EOF
            echo "Starting demo-sidecar application"
            mkdir -p /var/log/app
            i=0
            while true; do
              i=$((i+1))
              timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
              echo "{\"timestamp\":\"$timestamp\",\"level\":\"INFO\",\"message\":\"Processing file batch $i\",\"app\":\"demo-sidecar\",\"type\":\"batch\"}" >> /var/log/app/app.log
              if [ $((i % 8)) -eq 0 ]; then
                echo "{\"timestamp\":\"$timestamp\",\"level\":\"WARN\",\"message\":\"Batch $i took longer than expected\",\"app\":\"demo-sidecar\",\"duration_ms\":5000}" >> /var/log/app/app.log
              fi
              if [ $((i % 20)) -eq 0 ]; then
                echo "{\"timestamp\":\"$timestamp\",\"level\":\"ERROR\",\"message\":\"Failed to write batch $i to storage\",\"app\":\"demo-sidecar\",\"error\":\"Disk quota exceeded\"}" >> /var/log/app/app.log
              fi
              sleep 3
            done
          EOF
          ]

          volume_mount {
            name       = "app-logs"
            mount_path = "/var/log/app"
          }

          resources {
            requests = {
              memory = "32Mi"
              cpu    = "10m"
            }
            limits = {
              memory = "64Mi"
              cpu    = "50m"
            }
          }
        }

        # Elastic Agent sidecar container
        container {
          name  = "elastic-agent"
          image = "docker.elastic.co/elastic-agent/elastic-agent:${var.elastic_version}"

          env {
            name  = "FLEET_ENROLL"
            value = "1"
          }

          env {
            name  = "FLEET_URL"
            value = "https://fleet-server-agent-http.elastic-system.svc:8220"
          }

          env {
            name  = "FLEET_INSECURE"
            value = "true"
          }

          env {
            name  = "KIBANA_FLEET_SETUP"
            value = "1"
          }

          env {
            name  = "KIBANA_HOST"
            value = "https://kibana-kb-http.elastic-system.svc:5601"
          }

          env {
            name = "FLEET_ENROLLMENT_TOKEN"
            value_from {
              secret_key_ref {
                name     = "sidecar-enrollment-token"
                key      = "token"
                optional = false
              }
            }
          }

          volume_mount {
            name       = "app-logs"
            mount_path = "/var/log/app"
            read_only  = true
          }

          volume_mount {
            name       = "es-ca"
            mount_path = "/etc/elasticsearch/ca"
            read_only  = true
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "250m"
            }
          }

          security_context {
            run_as_user = 0
          }
        }

        volume {
          name = "app-logs"
          empty_dir {}
        }

        volume {
          name = "es-ca"
          secret {
            secret_name = kubernetes_secret.es_ca_app_demo.metadata[0].name
            items {
              key  = "ca.crt"
              path = "ca.crt"
            }
          }
        }
      }
    }
  }

  depends_on = [
    data.kubernetes_secret.sidecar_enrollment_token
  ]
}

# Read the enrollment token secret created by fleet-config Job
# This secret is created by the fleet-setup Job when it runs
data "kubernetes_secret" "sidecar_enrollment_token" {
  count = var.enable_sidecar_demo ? 1 : 0

  metadata {
    name      = "sidecar-enrollment-token"
    namespace = local.app_namespace
  }

  depends_on = [var.depends_on_fleet_config]
}

# =============================================================================
# Services (optional, for inter-app communication demos)
# =============================================================================

resource "kubernetes_service" "demo_api" {
  metadata {
    name      = "demo-api"
    namespace = local.app_namespace
  }

  spec {
    selector = {
      app = "demo-api"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "demo_webserver" {
  metadata {
    name      = "demo-webserver"
    namespace = local.app_namespace
  }

  spec {
    selector = {
      app = "demo-webserver"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
