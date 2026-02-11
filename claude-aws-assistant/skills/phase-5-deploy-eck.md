# Skill: Phase 5 - Deploy ECK Stack

Load this skill when guiding students through Phase 5 of the workshop.

## Overview

This phase deploys the complete Elastic Stack using ECK (Elastic Cloud on Kubernetes):
1. **ECK Operator** - Manages Elastic resources on Kubernetes
2. **Elasticsearch** - Search and analytics engine (logs cluster)
3. **Kibana** - Visualization and management UI
4. **Fleet Server** - Centralized agent management
5. **Elastic Agents** - Log collectors on each node
6. **Optional**: APM Server, Logstash, monitoring cluster

---

## Step-by-Step Guide

### Step 1: Verify Cluster is Ready

Before deploying, confirm the cluster is healthy:

```bash
kubectl get nodes
```

All nodes should show `Ready`.

---

### Step 2: Deploy the Complete Stack

Now we deploy everything else with a single command:

```bash
terraform apply -var-file="my-workshop.tfvars"
```

**Explain:**
```
This command deploys everything that wasn't already created. Since we've
already deployed VPC and EKS, Terraform will now add:

1. **ECK Operator** (via Helm)
   - A Kubernetes operator that understands Elastic resources
   - Watches for Elasticsearch, Kibana, Agent custom resources
   - Handles deployment, scaling, upgrades, TLS certificates

2. **Elasticsearch Cluster**
   - The heart of the stack - stores and indexes all logs
   - Deployed as a StatefulSet with persistent storage
   - Automatically configured with TLS encryption

3. **Kibana**
   - Web UI for searching logs and creating visualizations
   - Connects securely to Elasticsearch
   - Deployed as a Deployment with a Service

4. **Fleet Server**
   - Central management for Elastic Agents
   - Handles agent enrollment, configuration, and policies
   - Essential for agent management at scale

5. **Elastic Agents**
   - Deployed as a DaemonSet (one per node)
   - Collects logs and metrics from each Kubernetes node
   - Ships data to Elasticsearch via Fleet
```

Type `yes` when prompted.

**Expected duration**: ~5-10 minutes

---

### Step 3: Watch the Deployment

Open a watch on the elastic-system namespace to see pods come up:

```bash
kubectl get pods -n elastic-system -w
```

**Explain:**
```
The `-w` flag means "watch" - kubectl will continuously update as
pods are created and change status. You'll see:

1. ECK operator pods start first
2. Elasticsearch pods launch (may take a few minutes to become Ready)
3. Kibana pods follow once Elasticsearch is available
4. Fleet Server starts once Kibana is ready
5. Elastic Agents deploy to each node
```

**Status progression:**
- `Pending` → Waiting for resources
- `ContainerCreating` → Downloading images
- `Running` → Container running (but maybe not ready yet)
- `Running 1/1` → Fully ready

Press `Ctrl+C` to exit the watch when pods are running.

---

### Step 4: Check Elastic Resources Health

ECK provides custom resource types. Check their health:

```bash
kubectl get elasticsearch,kibana,agent,fleet -n elastic-system
```

**Expected output:**
```
NAME                                         HEALTH   NODES   VERSION   PHASE   AGE
elasticsearch.elasticsearch.k8s.elastic.co/logs   green    1       9.0.0     Ready   5m

NAME                                  HEALTH   NODES   VERSION   AGE
kibana.kibana.k8s.elastic.co/kibana   green    1       9.0.0     5m

NAME                                  HEALTH   AVAILABLE   EXPECTED   VERSION   AGE
agent.agent.k8s.elastic.co/fleet-server   green    1           1          9.0.0     5m
agent.agent.k8s.elastic.co/elastic-agent  green    2           2          9.0.0     5m
```

**Explain:**
```
This output shows the Elastic-specific resources:

- **Elasticsearch**: HEALTH=green means all shards are allocated
- **Kibana**: HEALTH=green means it's connected to Elasticsearch
- **Fleet Server**: AVAILABLE=1 means Fleet is running
- **Elastic Agent**: EXPECTED=2, AVAILABLE=2 means agents on all nodes
```

---

### Step 5: Understand What Got Deployed

Show the architecture:

```
## ECK Stack Architecture

┌─────────────────────────────────────────────────────────────────┐
│                      elastic-system namespace                    │
│                                                                  │
│  ┌────────────────┐     ┌────────────────┐                      │
│  │   Kibana       │────▶│  Elasticsearch │                      │
│  │   (UI)         │     │  (Data Store)  │                      │
│  └───────┬────────┘     └───────▲────────┘                      │
│          │                      │                                │
│          ▼                      │                                │
│  ┌────────────────┐            │                                │
│  │  Fleet Server  │            │                                │
│  │  (Mgmt Plane)  │            │                                │
│  └───────┬────────┘            │                                │
│          │                      │                                │
│          │ manages              │ ships logs                     │
│          ▼                      │                                │
│  ┌────────────────┐────────────┘                                │
│  │ Elastic Agents │  (DaemonSet - one per node)                 │
│  └────────────────┘                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Data Flow:
1. Elastic Agents collect logs from each Kubernetes node
2. Agents ship logs to Elasticsearch (coordinated by Fleet)
3. Kibana queries Elasticsearch to display logs
4. Fleet Server manages agent configuration centrally
```

---

### Step 6: Verify Elasticsearch Health

```bash
# Get the elastic user password
ELASTIC_PASSWORD=$(kubectl get secret logs-es-elastic-user -n elastic-system \
  -o jsonpath='{.data.elastic}' | base64 -d)

echo "Elasticsearch password: $ELASTIC_PASSWORD"
```

**Store this password** - you'll need it to log into Kibana.

Check Elasticsearch cluster health:

```bash
kubectl exec -n elastic-system logs-es-default-0 -- \
  curl -s -k -u "elastic:$ELASTIC_PASSWORD" \
  "https://localhost:9200/_cluster/health?pretty"
```

**Expected output:**
```json
{
  "cluster_name" : "logs",
  "status" : "green",
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 5,
  "active_shards" : 5,
  ...
}
```

**Explain:**
```
- status: "green" means all primary and replica shards are allocated
  (In a single-node cluster, "yellow" is also acceptable - replicas need
  a second node)
- number_of_nodes: How many Elasticsearch instances
- active_shards: Data is distributed across these shards
```

---

### Step 7: Check Fleet Server Status

```bash
kubectl logs -n elastic-system -l agent.k8s.elastic.co/name=fleet-server \
  --tail=20
```

Look for messages like:
- `Fleet Server is ready`
- `Enrolled in Fleet`

---

### Step 8: Check Elastic Agents

```bash
# List all agent pods
kubectl get pods -n elastic-system -l agent.k8s.elastic.co/name=elastic-agent

# Check one agent's logs
kubectl logs -n elastic-system -l agent.k8s.elastic.co/name=elastic-agent \
  --tail=20 | head -30
```

Look for:
- `Successfully enrolled`
- `Running inputs`

---

## Troubleshooting

### Elasticsearch stuck in "Pending"

**Cause**: Usually storage issues - PVC can't bind.

**Fix**:
```bash
kubectl get pvc -n elastic-system
kubectl describe pvc <pvc-name> -n elastic-system
```

Check for `ProvisioningFailed` events.

### Elasticsearch health "yellow"

**Cause**: Single-node cluster can't have replicas.

**Fix**: This is expected in dev. For this workshop, yellow is okay.
To see details:
```bash
kubectl exec -n elastic-system logs-es-default-0 -- \
  curl -s -k -u "elastic:$ELASTIC_PASSWORD" \
  "https://localhost:9200/_cat/indices?v"
```

### Kibana not becoming ready

**Cause**: Usually waiting for Elasticsearch.

**Fix**:
```bash
kubectl logs -n elastic-system -l kibana.k8s.elastic.co/name=kibana
```

Look for connection errors. Wait for ES to be green first.

### Agents not enrolling

**Cause**: Fleet Server not ready, or enrollment token issues.

**Fix**:
```bash
# Check Fleet Server status
kubectl get agent -n elastic-system

# Check agent logs
kubectl logs -n elastic-system -l agent.k8s.elastic.co/name=elastic-agent
```

### "ImagePullBackOff"

**Cause**: Can't download container image.

**Fix**:
```bash
kubectl describe pod <pod-name> -n elastic-system
```

Check if it's a network issue or image tag problem.

---

## Summary of Commands

```bash
# Deploy everything
terraform apply -var-file="my-workshop.tfvars"

# Watch pods come up
kubectl get pods -n elastic-system -w

# Check Elastic resources health
kubectl get elasticsearch,kibana,agent,fleet -n elastic-system

# Get Elasticsearch password
kubectl get secret logs-es-elastic-user -n elastic-system \
  -o jsonpath='{.data.elastic}' | base64 -d

# Check cluster health
kubectl exec -n elastic-system logs-es-default-0 -- \
  curl -s -k -u "elastic:$ELASTIC_PASSWORD" \
  "https://localhost:9200/_cluster/health?pretty"
```

---

## What Success Looks Like

Phase 5 is complete when:
1. ✓ ECK Operator running
2. ✓ Elasticsearch HEALTH=green (or yellow for single-node)
3. ✓ Kibana HEALTH=green
4. ✓ Fleet Server running and healthy
5. ✓ Elastic Agents deployed to all nodes
6. ✓ Elasticsearch password retrieved

---

## Transition to Phase 6

```
Fantastic! The entire Elastic Stack is now running on your Kubernetes
cluster!

You've deployed:
- Elasticsearch for storing and searching logs
- Kibana for visualization
- Fleet Server for agent management
- Elastic Agents collecting data from every node

All components are communicating securely over TLS, and the agents
are already collecting logs from your cluster.

Next up: Phase 6 - Verify & Explore

We'll access Kibana, log in, and see the logs flowing in real-time.
This is the payoff - seeing your observability stack in action!

Ready to see your logs? (**yes** / **no** / **tell me more**)
```
