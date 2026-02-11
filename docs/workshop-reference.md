# ECK Workshop Quick Reference

## Cluster Credentials

```bash
# Source environment (always run first!)
source /root/.workshop-env

# Logs cluster password
ES_PASSWORD=$(kubectl get secret logs-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)

# Monitoring cluster password
MON_PASSWORD=$(kubectl get secret monitoring-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)
```

## Accessing Kibana

### Via Jump Box (Recommended)
```bash
# Get jumpbox IP
terraform output jumpbox_public_ip

# Get password command
terraform output jumpbox_password_command
```

Then RDP to the jumpbox and browse to:
- **Logs Kibana**: https://kibana.elastic.internal
- **Monitoring Kibana**: https://monitoring.elastic.internal

### Via Port Forward
```bash
# Logs Kibana
kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601 &

# Monitoring Kibana (different port)
kubectl port-forward svc/monitoring-kb-http -n elastic-system 5602:5601 &
```

---

## Agent Deployment Patterns

| Pattern | Use Case | Spec Field |
|---------|----------|------------|
| **DaemonSet** | Infrastructure monitoring (one per node) | `spec.daemonSet: {}` |
| **Sidecar** | App-specific logs (in app pod) | Container in pod spec |
| **Standalone** | Fleet Server, APM (single instance) | `spec.deployment: {replicas: 1}` |

### What We Deploy

| Agent | Pattern | Purpose |
|-------|---------|---------|
| Fleet Server | Standalone | Manages all agents |
| Elastic Agent | DaemonSet | Node metrics & logs |
| APM Server | Standalone | Application traces |
| Infra Monitor | DaemonSet | Metrics to monitoring cluster |

---

## Useful kubectl Commands

```bash
# Check all ECK resources
kubectl get elasticsearch,kibana,agent -n elastic-system

# Watch pods
kubectl get pods -n elastic-system -w

# Check specific agent
kubectl get agent <name> -n elastic-system -o yaml

# View agent logs
kubectl logs -n elastic-system -l agent.k8s.elastic.co/name=elastic-agent --tail=50

# Check Gateway API
kubectl get gateway,httproute -n elastic-system

# Check sample apps
kubectl get pods -n app-demo

# Check OTel demo
kubectl get pods -n otel-demo
```

---

## Terraform Modules

| Phase | Modules |
|-------|---------|
| 2 - Infrastructure | `vpc`, `eks`, `jumpbox` |
| 3 - ECK Stack | `eck_operator`, `elasticsearch_logs`, `elasticsearch_monitoring`, `kibana`, `envoy_gateway_base`, `gateway_api`, `route53_private` |
| 4 - Fleet | `fleet_config`, `fleet_server`, `elastic_agents`, `infra_monitoring_agent`, `sample_apps` |
| 5 - APM | `apm_server` + OTel Demo (Helm) |
| 6 - ML | Manual kubectl patch for ML nodes |
| 7 - AI | Manual connector configuration |

---

## Namespaces

| Namespace | Contents |
|-----------|----------|
| `elastic-system` | All Elastic resources (ES, Kibana, Fleet, APM) |
| `envoy-gateway-system` | Envoy Gateway controller |
| `app-demo` | Sample demo applications |
| `otel-demo` | OpenTelemetry demo (Phase 5) |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No AWS credentials | `source /root/.workshop-env` |
| kubectl connection refused | `aws eks update-kubeconfig --name $TF_VAR_cluster_name --region us-east-2` |
| Pods pending | `kubectl describe pod <name> -n elastic-system` |
| ES yellow health | Normal with single replica |
| State lock error | Wait or `rm .terraform.lock.hcl` |
| Jumpbox RDP fails | Check security group allows your IP on 3389 |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                     │
├──────────────────────────┬──────────────────────────────────┤
│     Public Subnets       │        Private Subnets           │
│  ┌──────────────────┐    │   ┌────────────────────────┐     │
│  │   NAT Gateway    │    │   │      EKS Cluster       │     │
│  │   Jump Box (RDP) │    │   │  ┌─────────────────┐   │     │
│  └──────────────────┘    │   │  │  Node Groups:   │   │     │
│                          │   │  │  - system       │   │     │
│                          │   │  │  - elastic      │   │     │
│                          │   │  │  - apps         │   │     │
│                          │   │  │  - ml (Phase 6) │   │     │
│                          │   │  └─────────────────┘   │     │
│                          │   │                        │     │
│                          │   │  Workloads:            │     │
│                          │   │  - Elasticsearch       │     │
│                          │   │  - Kibana              │     │
│                          │   │  - Fleet Server        │     │
│                          │   │  - Elastic Agents      │     │
│                          │   │  - APM Server          │     │
│                          │   │  - Envoy Gateway       │     │
│                          │   └────────────────────────┘     │
└──────────────────────────┴──────────────────────────────────┘
                              │
                    Route53 Private Zone
                    (*.elastic.internal)
```

---

## Workshop Commands (Claude Code)

If using Claude Code AI assistant:

| Command | Description |
|---------|-------------|
| `/workshop` | Start or resume |
| `/status` | Check progress |
| `/verify` | Verify phase completion |
| `/troubleshoot` | Get help |
| `/cleanup` | Tear down resources |
