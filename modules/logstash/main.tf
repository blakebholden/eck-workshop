# Logstash Module
# Deploys Logstash for data processing pipelines
# Useful for complex transformations, multiple inputs, and enrichment

resource "kubectl_manifest" "logstash" {
  yaml_body = <<-YAML
apiVersion: logstash.k8s.elastic.co/v1alpha1
kind: Logstash
metadata:
  name: logstash
  namespace: ${var.namespace}
spec:
  version: ${var.elastic_version}
  count: ${var.replicas}
  elasticsearchRefs:
    - name: ${var.elasticsearch_name}
      clusterName: ${var.elasticsearch_cluster_name}
  podTemplate:
    spec:
      containers:
        - name: logstash
          resources:
            requests:
              memory: ${var.memory_request}
              cpu: ${var.cpu_request}
            limits:
              memory: ${var.memory_limit}
              cpu: ${var.cpu_limit}
  pipelines:
    - pipeline.id: main
      config.string: |
        input {
          beats {
            port => 5044
          }
          http {
            port => 8080
            codec => json
          }
        }

        filter {
          # Add timestamp if not present
          if ![timestamp] {
            mutate {
              add_field => { "timestamp" => "%%{@timestamp}" }
            }
          }

          # Parse JSON in message field if present
          if [message] =~ /^\{.*\}$/ {
            json {
              source => "message"
              target => "parsed"
              skip_on_invalid_json => true
            }
          }

          # Add processing metadata
          mutate {
            add_field => {
              "[ecs][version]" => "8.0.0"
              "[event][ingested]" => "%%{@timestamp}"
              "[event][module]" => "logstash"
            }
          }
        }

        output {
          elasticsearch {
            hosts => ["https://logs-es-http.elastic-system.svc:9200"]
            user => "$${LOGS_ES_USER}"
            password => "$${LOGS_ES_PASSWORD}"
            ssl_enabled => true
            ssl_certificate_authorities => ["$${LOGS_ES_SSL_CERTIFICATE_AUTHORITY}"]
            data_stream => true
            data_stream_type => "logs"
            data_stream_dataset => "logstash"
            data_stream_namespace => "default"
          }
        }
  services:
    - name: beats
      service:
        spec:
          type: ClusterIP
          ports:
            - port: 5044
              name: beats
              protocol: TCP
              targetPort: 5044
    - name: http
      service:
        spec:
          type: ClusterIP
          ports:
            - port: 8080
              name: http
              protocol: TCP
              targetPort: 8080
  YAML

  depends_on = [var.depends_on_elasticsearch]
}

# ConfigMap for additional Logstash pipelines (can be extended)
resource "kubectl_manifest" "logstash_pipelines_config" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-pipelines
  namespace: ${var.namespace}
data:
  syslog.conf: |
    input {
      syslog {
        port => 5514
        type => "syslog"
      }
    }
    filter {
      if [type] == "syslog" {
        grok {
          match => { "message" => "%%{SYSLOGTIMESTAMP:syslog_timestamp} %%{SYSLOGHOST:syslog_hostname} %%{DATA:syslog_program}(?:\[%%{POSINT:syslog_pid}\])?: %%{GREEDYDATA:syslog_message}" }
        }
        date {
          match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
        }
      }
    }
    output {
      elasticsearch {
        hosts => ["https://${var.elasticsearch_name}-es-http.${var.namespace}.svc:9200"]
        ssl_enabled => true
        index => "syslog-%%{+YYYY.MM.dd}"
      }
    }
  YAML
}
