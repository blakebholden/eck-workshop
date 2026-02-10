# Fleet Configuration Module
# Configures Fleet policies, integrations, outputs, and imports dashboards

# =============================================================================
# Get ES CA Certificate for Fleet Output
# =============================================================================

data "kubernetes_secret" "es_ca" {
  metadata {
    name      = "logs-es-http-certs-public"
    namespace = "elastic-system"
  }
}

# =============================================================================
# ServiceAccount and RBAC for Fleet Setup Job
# =============================================================================

resource "kubernetes_service_account" "fleet_setup" {
  metadata {
    name      = "fleet-setup"
    namespace = "elastic-system"
  }
}

resource "kubernetes_cluster_role" "fleet_setup" {
  metadata {
    name = "fleet-setup"
  }

  # Create namespaces
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "create", "patch"]
  }

  # Create secrets in any namespace
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "patch", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "fleet_setup" {
  metadata {
    name = "fleet-setup"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fleet_setup.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fleet_setup.metadata[0].name
    namespace = "elastic-system"
  }
}

# =============================================================================
# Fleet Configuration Job
# Creates agent policies, outputs, and adds integrations via Kibana API
# This Job is idempotent - it handles existing resources gracefully
# =============================================================================

resource "kubectl_manifest" "fleet_setup" {
  yaml_body = <<-YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: fleet-setup
  namespace: elastic-system
  labels:
    app: fleet-setup
spec:
  ttlSecondsAfterFinished: 300
  backoffLimit: 10
  template:
    spec:
      restartPolicy: OnFailure
      serviceAccountName: fleet-setup
      containers:
      - name: fleet-setup
        image: alpine/k8s:1.29.0
        command:
        - /bin/sh
        - -c
        - |
          set -e

          KIBANA_URL="https://kibana-kb-http.elastic-system.svc:5601"
          ES_URL="https://logs-es-http.elastic-system.svc:9200"

          # Wait for Kibana to be ready
          echo "Waiting for Kibana..."
          until curl -sk -u "elastic:$${ES_PASSWORD}" "$${KIBANA_URL}/api/status" | grep -q '"level":"available"'; do
            echo "Waiting for Kibana to be ready..."
            sleep 5
          done
          echo "Kibana is ready!"

          # =================================================================
          # Create Fleet Server Policy FIRST (required before Fleet Server starts)
          # =================================================================
          echo "Creating Fleet Server policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/agent_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "Fleet Server Policy",
              "description": "Policy for Fleet Server",
              "namespace": "default",
              "monitoring_enabled": ["logs", "metrics"],
              "id": "fleet-server-policy",
              "is_default_fleet_server": true
            }' || echo "Fleet Server policy may already exist"
          echo ""

          # Install Fleet Server integration package and get version
          echo "Installing Fleet Server integration..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/epm/packages/fleet_server" \
            -H "kbn-xsrf: true" || echo "Package may already be installed"

          # Get the installed fleet_server package version
          FLEET_SERVER_VERSION=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/epm/packages/fleet_server" \
            -H "kbn-xsrf: true" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Fleet Server package version: $FLEET_SERVER_VERSION"

          # Add Fleet Server integration to policy (REQUIRED for Fleet Server to start)
          echo "Adding Fleet Server integration to policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/package_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"fleet_server-1\",
              \"namespace\": \"default\",
              \"policy_id\": \"fleet-server-policy\",
              \"package\": {
                \"name\": \"fleet_server\",
                \"version\": \"$FLEET_SERVER_VERSION\"
              }
            }" || echo "Fleet Server integration may already exist"
          echo ""

          # =================================================================
          # Create Fleet Output with CA Certificate (for sidecar agents)
          # =================================================================
          echo "Creating Fleet output with CA certificate..."
          # Read CA cert from mounted secret and escape for JSON
          ES_CA_CERT=$(cat /etc/elasticsearch/certs/ca.crt | sed ':a;N;$!ba;s/\n/\\n/g')
          OUTPUT_RESULT=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/outputs" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"elasticsearch-with-ca\",
              \"type\": \"elasticsearch\",
              \"hosts\": [\"https://logs-es-http.elastic-system.svc:9200\"],
              \"is_default\": false,
              \"ssl\": {
                \"certificate_authorities\": [\"$ES_CA_CERT\"]
              }
            }" 2>&1)

          if echo "$OUTPUT_RESULT" | grep -q '"item"'; then
            OUTPUT_ID=$(echo "$OUTPUT_RESULT" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Created output with ID: $OUTPUT_ID"
          elif echo "$OUTPUT_RESULT" | grep -q 'already exists'; then
            echo "Output already exists, getting ID..."
            OUTPUT_ID=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
              "$${KIBANA_URL}/api/fleet/outputs" \
              -H "kbn-xsrf: true" | grep -o '"id":"[^"]*","name":"elasticsearch-with-ca"' | cut -d'"' -f4)
            echo "Existing output ID: $OUTPUT_ID"
          else
            echo "Output creation response: $OUTPUT_RESULT"
            OUTPUT_ID=""
          fi

          # =================================================================
          # Create Kubernetes Agent Policy
          # =================================================================
          echo "Creating Kubernetes agent policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/agent_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "Kubernetes Policy",
              "description": "Policy for Kubernetes node agents - collects logs and metrics",
              "namespace": "default",
              "monitoring_enabled": ["logs", "metrics"],
              "inactivity_timeout": 1209600,
              "id": "kubernetes-policy"
            }' || echo "Kubernetes policy may already exist"
          echo ""

          # =================================================================
          # Create APM Server Policy
          # =================================================================
          echo "Creating APM Server policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/agent_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "APM Server Policy",
              "description": "Policy for APM Server agents",
              "namespace": "default",
              "monitoring_enabled": ["logs", "metrics"],
              "id": "apm-server-policy"
            }' || echo "APM policy may already exist"
          echo ""

          # =================================================================
          # Create Sidecar Policy (uses output with CA)
          # =================================================================
          echo "Creating Sidecar agent policy..."
          if [ -n "$OUTPUT_ID" ]; then
            curl -sk -u "elastic:$${ES_PASSWORD}" \
              -X POST "$${KIBANA_URL}/api/fleet/agent_policies" \
              -H "kbn-xsrf: true" \
              -H "Content-Type: application/json" \
              -d "{
                \"name\": \"Sidecar Policy\",
                \"description\": \"Policy for Elastic Agent sidecars in application pods\",
                \"namespace\": \"default\",
                \"monitoring_enabled\": [\"logs\"],
                \"id\": \"sidecar-policy\",
                \"data_output_id\": \"$OUTPUT_ID\",
                \"monitoring_output_id\": \"$OUTPUT_ID\"
              }" || echo "Sidecar policy may already exist"
          else
            curl -sk -u "elastic:$${ES_PASSWORD}" \
              -X POST "$${KIBANA_URL}/api/fleet/agent_policies" \
              -H "kbn-xsrf: true" \
              -H "Content-Type: application/json" \
              -d '{
                "name": "Sidecar Policy",
                "description": "Policy for Elastic Agent sidecars in application pods",
                "namespace": "default",
                "monitoring_enabled": ["logs"],
                "id": "sidecar-policy"
              }' || echo "Sidecar policy may already exist"
          fi
          echo ""

          # =================================================================
          # Create Sidecar Enrollment Token
          # =================================================================
          echo "Creating sidecar enrollment token..."
          TOKEN_RESULT=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/enrollment_api_keys" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d '{
              "name": "sidecar-enrollment-key",
              "policy_id": "sidecar-policy"
            }' 2>&1)

          if echo "$TOKEN_RESULT" | grep -q '"api_key"'; then
            ENROLLMENT_TOKEN=$(echo "$TOKEN_RESULT" | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4)
            echo "Enrollment token created successfully"

            # Create app-demo namespace if it doesn't exist
            echo "Ensuring app-demo namespace exists..."
            kubectl create namespace app-demo --dry-run=client -o yaml | kubectl apply -f -

            # Store token in a secret for sample-apps to use
            echo "Storing enrollment token in secret..."
            kubectl create secret generic sidecar-enrollment-token \
              --namespace app-demo \
              --from-literal=token="$ENROLLMENT_TOKEN" \
              --dry-run=client -o yaml | kubectl apply -f -
            kubectl label secret sidecar-enrollment-token -n app-demo app.kubernetes.io/managed-by=fleet-config --overwrite || true
            echo "Enrollment token stored in secret"
          else
            echo "Token creation response: $TOKEN_RESULT"
          fi

          # =================================================================
          # Install and add Kubernetes Integration
          # =================================================================
          echo "Installing Kubernetes integration package..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/epm/packages/kubernetes" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" || echo "Package may already be installed"

          # Get the installed kubernetes package version
          K8S_VERSION=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/epm/packages/kubernetes" \
            -H "kbn-xsrf: true" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Kubernetes package version: $K8S_VERSION"

          echo "Adding Kubernetes integration to policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/package_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"kubernetes-1\",
              \"description\": \"Kubernetes integration for container logs and metrics\",
              \"namespace\": \"default\",
              \"policy_id\": \"kubernetes-policy\",
              \"package\": {
                \"name\": \"kubernetes\",
                \"version\": \"$K8S_VERSION\"
              }
            }" || echo "Kubernetes integration may already exist"
          echo ""

          # =================================================================
          # Install and add System Integration (for Infrastructure UI)
          # =================================================================
          echo "Installing System integration package..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/epm/packages/system" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" || echo "Package may already be installed"

          # Get the installed system package version
          SYSTEM_VERSION=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/epm/packages/system" \
            -H "kbn-xsrf: true" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "System package version: $SYSTEM_VERSION"

          echo "Adding System integration to Kubernetes policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/package_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"system-1\",
              \"description\": \"System metrics for host infrastructure monitoring\",
              \"namespace\": \"default\",
              \"policy_id\": \"kubernetes-policy\",
              \"package\": {
                \"name\": \"system\",
                \"version\": \"$SYSTEM_VERSION\"
              }
            }" || echo "System integration may already exist"
          echo ""

          # =================================================================
          # Install and add APM Integration
          # =================================================================
          echo "Installing APM integration package..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/epm/packages/apm" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" || echo "Package may already be installed"

          # Get the installed APM package version
          APM_VERSION=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/epm/packages/apm" \
            -H "kbn-xsrf: true" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "APM package version: $APM_VERSION"

          echo "Adding APM integration to policy..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/package_policies" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"apm-1\",
              \"description\": \"APM Server integration\",
              \"namespace\": \"default\",
              \"policy_id\": \"apm-server-policy\",
              \"package\": {
                \"name\": \"apm\",
                \"version\": \"$APM_VERSION\"
              },
              \"inputs\": [
                {
                  \"type\": \"apm\",
                  \"enabled\": true,
                  \"vars\": {
                    \"host\": {\"value\": \"0.0.0.0:8200\"},
                    \"url\": {\"value\": \"https://apm.elastic.internal:8200\"}
                  }
                }
              ]
            }" || echo "APM integration may already exist"
          echo ""

          # =================================================================
          # Install Filestream Integration (for sidecar)
          # =================================================================
          echo "Installing Filestream integration package..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            -X POST "$${KIBANA_URL}/api/fleet/epm/packages/filestream" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" || echo "Package may already be installed"
          echo ""

          # =================================================================
          # Verify Fleet Server policy has integration (CRITICAL)
          # =================================================================
          echo "Verifying Fleet Server policy has integration..."
          FLEET_SERVER_INTEGRATIONS=$(curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/agent_policies/fleet-server-policy" \
            -H "kbn-xsrf: true" | grep -o '"package_policies":\[[^]]*\]')

          if echo "$FLEET_SERVER_INTEGRATIONS" | grep -q "fleet_server"; then
            echo "✓ Fleet Server policy has fleet_server integration attached"
          else
            echo "WARNING: Fleet Server policy may be missing fleet_server integration!"
            echo "Fleet Server will NOT start without this integration."
          fi

          # =================================================================
          # Verify policies were created
          # =================================================================
          echo ""
          echo "Verifying agent policies..."
          curl -sk -u "elastic:$${ES_PASSWORD}" \
            "$${KIBANA_URL}/api/fleet/agent_policies" \
            -H "kbn-xsrf: true" | grep -o '"name":"[^"]*"'

          echo ""
          echo "Fleet setup complete!"
        env:
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: logs-es-elastic-user
              key: elastic
        volumeMounts:
        - name: es-certs
          mountPath: /etc/elasticsearch/certs
          readOnly: true
      volumes:
      - name: es-certs
        secret:
          secretName: logs-es-http-certs-public
  YAML

  depends_on = [
    kubernetes_service_account.fleet_setup,
    kubernetes_cluster_role_binding.fleet_setup
  ]

  lifecycle {
    replace_triggered_by = [
      # Recreate job when configuration changes
    ]
  }
}

# =============================================================================
# Wait for Fleet Setup to Complete
# =============================================================================

resource "time_sleep" "wait_for_fleet_setup" {
  depends_on = [kubectl_manifest.fleet_setup]

  create_duration = "30s"
}

# =============================================================================
# Dashboard Import Job
# =============================================================================

# ConfigMap containing the dashboard ndjson file
resource "kubernetes_config_map" "dashboard_ndjson" {
  count = var.import_dashboards && var.dashboard_ndjson_path != "" ? 1 : 0

  metadata {
    name      = "dashboard-ndjson"
    namespace = "elastic-system"
  }

  data = {
    "dashboard.ndjson" = file(var.dashboard_ndjson_path)
  }
}

resource "kubectl_manifest" "dashboard_import" {
  count = var.import_dashboards ? 1 : 0

  yaml_body = <<-YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: dashboard-import
  namespace: elastic-system
spec:
  ttlSecondsAfterFinished: 600
  backoffLimit: 5
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: dashboard-import
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          set -e

          KIBANA_URL="https://kibana-kb-http.elastic-system.svc:5601"

          # Wait for Kibana to be ready
          echo "Waiting for Kibana..."
          until curl -sk -u "elastic:$${ES_PASSWORD}" "$${KIBANA_URL}/api/status" | grep -q '"level":"available"'; do
            echo "Waiting for Kibana..."
            sleep 10
          done

          echo "Importing dashboards..."

          # Check if dashboard ndjson file exists
          if [ -f /dashboards/dashboard.ndjson ]; then
            echo "Importing App Demo Dashboard from ndjson file..."
            curl -sk -u "elastic:$${ES_PASSWORD}" \
              -X POST "$${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
              -H "kbn-xsrf: true" \
              -F file=@/dashboards/dashboard.ndjson
            echo ""
            echo "Dashboard import response received."
          else
            echo "No dashboard.ndjson file found, creating basic index patterns..."

            # Create index patterns as fallback
            echo "Creating logs-* index pattern..."
            curl -sk -u "elastic:$${ES_PASSWORD}" \
              -X POST "$${KIBANA_URL}/api/saved_objects/index-pattern/logs-*" \
              -H "kbn-xsrf: true" \
              -H "Content-Type: application/json" \
              -d '{
                "attributes": {
                  "title": "logs-*",
                  "timeFieldName": "@timestamp"
                }
              }' || echo "Index pattern may already exist"

            echo "Creating metrics-* index pattern..."
            curl -sk -u "elastic:$${ES_PASSWORD}" \
              -X POST "$${KIBANA_URL}/api/saved_objects/index-pattern/metrics-*" \
              -H "kbn-xsrf: true" \
              -H "Content-Type: application/json" \
              -d '{
                "attributes": {
                  "title": "metrics-*",
                  "timeFieldName": "@timestamp"
                }
              }' || echo "Index pattern may already exist"
          fi

          echo ""
          echo "Dashboard import complete!"
        env:
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: logs-es-elastic-user
              key: elastic
        volumeMounts:
        - name: dashboards
          mountPath: /dashboards
          readOnly: true
      volumes:
      - name: dashboards
        configMap:
          name: dashboard-ndjson
          optional: true
  YAML

  depends_on = [time_sleep.wait_for_fleet_setup, kubernetes_config_map.dashboard_ndjson]
}
