# /verify - Verify Current Phase is Complete

When the user runs `/verify`, check if they've completed their current phase.

## 1. Read State

Read `.workshop-state.json` to get the current phase.

## 2. Run Verification Based on Phase

### Phase 1: Environment Setup
Run these checks:
```bash
source /root/.workshop-env
aws sts get-caller-identity
echo $TF_VAR_cluster_name
aws --version
terraform --version
kubectl version --client
helm version
```

**Pass if**:
- AWS credentials work
- Cluster name is set
- All 4 tools return version info

### Phase 2: Deploy Infrastructure
Run:
```bash
kubectl get nodes
```

**Pass if**:
- Nodes are listed
- All nodes show STATUS=Ready

### Phase 3: Deploy ECK Stack
Run:
```bash
kubectl get elasticsearch,kibana -n elastic-system
kubectl get gateway -n elastic-system
```

**Pass if**:
- Elasticsearch HEALTH=green (or yellow with single replica)
- Kibana HEALTH=green
- Gateway exists

### Phase 4: Fleet & Monitoring
Run:
```bash
kubectl get agent -n elastic-system
kubectl get pods -n elastic-system -l agent.k8s.elastic.co/name=fleet-server
kubectl get pods -n elastic-system -l agent.k8s.elastic.co/name=elastic-agent
```

**Pass if**:
- Fleet Server agent is healthy
- Elastic Agent DaemonSet is running on nodes

### Phase 5: APM & Observability
Run:
```bash
kubectl get agent apm-server -n elastic-system
kubectl get pods -n otel-demo
```

**Pass if**:
- APM Server is healthy
- OTel Demo pods are running (some may be pending - that's OK)

### Phase 6: ML & ELSER
Run:
```bash
kubectl get pods -n elastic-system -l elasticsearch.k8s.elastic.co/cluster-name=logs | grep ml

ES_PASSWORD=$(kubectl get secret logs-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)
kubectl exec -n elastic-system logs-es-default-0 -- curl -s -k \
  -u "elastic:$ES_PASSWORD" \
  "https://localhost:9200/_ml/trained_models/.elser_model_2_linux-x86_64/_stats" | grep -o '"state":"[^"]*"'
```

**Pass if**:
- ML node pod is running (logs-es-ml-0)
- ELSER model state is "started"

### Phase 7: AI Assistant
Run:
```bash
ES_PASSWORD=$(kubectl get secret logs-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d)
kubectl exec -n elastic-system logs-es-default-0 -- curl -s -k \
  -u "elastic:$ES_PASSWORD" \
  "https://localhost:9200/.kibana/_search" \
  -H "Content-Type: application/json" \
  -d '{"query":{"term":{"type":"action"}},"size":1}' | grep -o '"actionTypeId":"[^"]*"'
```

**Pass if**:
- LLM connector action exists in Kibana

### Phase 8: Exploration
This phase has no verification - it's free exploration time.

```
Phase 8 is for exploration! There's nothing to verify.

Some things you can try:
- Build custom dashboards in Kibana
- Set up alerting rules
- Explore APM traces
- Try semantic search with ELSER
- Ask the AI Assistant questions

Run /cleanup when you're ready to tear down resources.
```

## 3. Handle Results

### If Passed:
```
## Phase {N} Complete!

Great work! You've successfully completed {phase name}.

{Brief summary of what they accomplished}

Ready for Phase {N+1}: {next phase name}?
```

Update `.workshop-state.json`:
- Increment `currentPhase`
- Add phase to `completedSteps`
- Update `lastActivity`

### If Failed:
```
## Not quite there yet

{Specific item that failed}:
{The actual output or error}

Here's how to fix it:
{Specific guidance}

Try again and run /verify when ready.
```

Do NOT advance the phase.
