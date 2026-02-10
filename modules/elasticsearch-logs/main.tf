# Elasticsearch Logs Cluster Module
# Main logging cluster for collecting all application and system logs

# =============================================================================
# Elasticsearch Logs Cluster
# =============================================================================

resource "kubectl_manifest" "elasticsearch_logs" {
  yaml_body = <<-YAML
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: logs
  namespace: elastic-system
spec:
  version: ${var.elastic_version}

  # Stack Monitoring - send metrics to monitoring cluster
  monitoring:
    metrics:
      elasticsearchRefs:
      - name: monitoring
        namespace: elastic-system
    logs:
      elasticsearchRefs:
      - name: monitoring
        namespace: elastic-system

  nodeSets:
  - name: default
    count: ${var.node_count}
    config:
      # Disable memory mapping for containerized environments
      node.store.allow_mmap: false

      # NOTE: Do NOT set discovery.type - ECK handles this automatically
      # Setting it conflicts with ECK's cluster.initial_master_nodes bootstrap

      # Cluster settings
      cluster.routing.allocation.disk.threshold_enabled: true
      cluster.routing.allocation.disk.watermark.low: 85%
      cluster.routing.allocation.disk.watermark.high: 90%
      cluster.routing.allocation.disk.watermark.flood_stage: 95%

      # Node roles (all nodes are data + master eligible for dev)
      # remote_cluster_client is required for stack monitoring to send data to monitoring cluster
      node.roles:
        - master
        - data
        - data_content
        - data_hot
        - ingest
        - transform
        - remote_cluster_client

    podTemplate:
      metadata:
        labels:
          app: elasticsearch
          cluster: logs
      spec:
        # Schedule on dedicated elastic nodes
        nodeSelector:
          node-group: elastic

        # Tolerate the elasticsearch taint
        tolerations:
        - key: dedicated
          operator: Equal
          value: elasticsearch
          effect: NoSchedule

        # Init container to set vm.max_map_count (optional, mmap disabled)
        initContainers:
        - name: sysctl
          securityContext:
            privileged: true
            runAsUser: 0
          command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']

        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 4Gi
              cpu: 1
            limits:
              memory: 4Gi
              cpu: 2
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms2g -Xmx2g"

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

  # ML Nodes for ELSER and other ML workloads
  # Runs on dedicated ML node group (m5.xlarge - 4 vCPU, 16GB RAM)
  - name: ml
    count: 1
    config:
      node.store.allow_mmap: false
      node.roles:
        - ml
        - remote_cluster_client
      xpack.ml.enabled: true
      xpack.ml.max_machine_memory_percent: 80

    podTemplate:
      metadata:
        labels:
          app: elasticsearch
          cluster: logs
          node-type: ml
      spec:
        # Run on dedicated ML node group
        nodeSelector:
          node-group: ml

        # Tolerate the ML node taint
        tolerations:
        - key: dedicated
          operator: Equal
          value: ml
          effect: NoSchedule

        initContainers:
        - name: sysctl
          securityContext:
            privileged: true
            runAsUser: 0
          command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']

        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 8Gi
              cpu: 2
            limits:
              memory: 12Gi
              cpu: 4
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms6g -Xmx6g"

    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 20Gi
        storageClassName: gp3

  # HTTP settings
  http:
    tls:
      selfSignedCertificate:
        disabled: false
        subjectAltNames:
        - dns: logs-es-http.elastic-system.svc
        - dns: logs-es-http.elastic-system.svc.cluster.local
        - dns: "*.logs-es-default.elastic-system.svc"
  YAML

  depends_on = [var.depends_on_operator]
}

# =============================================================================
# Wait for Elasticsearch to be ready
# =============================================================================

resource "time_sleep" "wait_for_elasticsearch" {
  depends_on = [kubectl_manifest.elasticsearch_logs]

  create_duration = "90s"  # Allow ES pods to start; license job has internal retry logic
}

# =============================================================================
# Enable Enterprise Trial License
# =============================================================================

# Job to enable trial license after Elasticsearch is ready
resource "kubectl_manifest" "enable_trial_license" {
  count = var.enable_trial_license ? 1 : 0

  depends_on = [time_sleep.wait_for_elasticsearch]

  yaml_body = <<-YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: enable-trial-license
  namespace: elastic-system
spec:
  ttlSecondsAfterFinished: 300
  backoffLimit: 10
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: enable-license
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          set -e

          MAX_RETRIES=30
          RETRY_INTERVAL=10

          echo "Waiting for Elasticsearch to be ready..."
          retries=0
          until curl -sk -u "elastic:$${ES_PASSWORD}" "https://logs-es-http.elastic-system.svc:9200/_cluster/health" | grep -q '"status"'; do
            retries=$((retries + 1))
            if [ $retries -ge $MAX_RETRIES ]; then
              echo "ERROR: Elasticsearch not ready after $MAX_RETRIES attempts"
              exit 1
            fi
            echo "Attempt $retries/$MAX_RETRIES - Waiting for Elasticsearch..."
            sleep $RETRY_INTERVAL
          done

          # Wait for cluster health to be at least yellow
          echo "Waiting for cluster health to be yellow or green..."
          retries=0
          until curl -sk -u "elastic:$${ES_PASSWORD}" "https://logs-es-http.elastic-system.svc:9200/_cluster/health" | grep -qE '"status"\s*:\s*"(yellow|green)"'; do
            retries=$((retries + 1))
            if [ $retries -ge $MAX_RETRIES ]; then
              echo "WARNING: Cluster not healthy after $MAX_RETRIES attempts, proceeding anyway..."
              break
            fi
            echo "Attempt $retries/$MAX_RETRIES - Waiting for cluster health..."
            sleep $RETRY_INTERVAL
          done

          # Check current license
          echo "Current license:"
          curl -sk -u "elastic:$${ES_PASSWORD}" "https://logs-es-http.elastic-system.svc:9200/_license"

          # Start trial license with retry
          echo ""
          echo "Starting trial license..."
          retries=0
          while [ $retries -lt 5 ]; do
            RESULT=$(curl -sk -u "elastic:$${ES_PASSWORD}" -X POST "https://logs-es-http.elastic-system.svc:9200/_license/start_trial?acknowledge=true")
            echo "$RESULT"
            if echo "$RESULT" | grep -q '"acknowledged"\s*:\s*true'; then
              echo "Trial license activated successfully!"
              break
            elif echo "$RESULT" | grep -q '"trial_was_started"\s*:\s*true'; then
              echo "Trial license was already started!"
              break
            fi
            retries=$((retries + 1))
            echo "Retry $retries/5..."
            sleep 5
          done

          echo ""
          echo "Final license status:"
          curl -sk -u "elastic:$${ES_PASSWORD}" "https://logs-es-http.elastic-system.svc:9200/_license"
        env:
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: logs-es-elastic-user
              key: elastic
  YAML
}

