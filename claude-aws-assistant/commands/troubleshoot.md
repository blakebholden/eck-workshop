# /troubleshoot - Diagnose and Fix Issues

When the user runs `/troubleshoot`, help them debug their current situation.

## 1. Gather Context

First, understand where they are:

```
Let me check a few things to understand what's happening...
```

Run these diagnostic commands:

```bash
# Source environment first
source /root/.workshop-env 2>&1

# Check AWS
aws sts get-caller-identity 2>&1

# Check cluster name
echo "Cluster: $TF_VAR_cluster_name"

# Check if in right directory
ls terraform/*.tf 2>&1

# Check Kubernetes (if applicable)
kubectl get nodes 2>&1

# Check Elastic (if applicable)
kubectl get pods -n elastic-system 2>&1
```

## 2. Identify the Problem

Based on the output, categorize the issue:

### AWS Issues
| Error | Cause | Fix |
|-------|-------|-----|
| "Unable to locate credentials" | Environment not sourced | `source /root/.workshop-env` |
| "ExpiredToken" | Credentials expired | Re-run setup script or refresh creds |
| "AccessDenied" | Permissions issue | Check IAM role |
| Region issues | Wrong region | Set `export AWS_REGION=us-east-2` |

### Terraform Issues
| Error | Cause | Fix |
|-------|-------|-----|
| "No configuration files" | Wrong directory | `cd /root/workshop/terraform` |
| "Error acquiring state lock" | Stale lock | Wait or `rm .terraform.lock.hcl` |
| "Provider not found" | Not initialized | `terraform init` |
| Resource errors | Various | Read specific error message |

### Kubernetes Issues
| Error | Cause | Fix |
|-------|-------|-----|
| "connection refused" | kubectl not configured | `aws eks update-kubeconfig --name $TF_VAR_cluster_name --region us-east-2` |
| "nodes not found" | Cluster doesn't exist | Deploy infrastructure first |
| Pods in `Pending` | Resource constraints | `kubectl describe pod <name>` |
| Pods in `CrashLoopBackOff` | App error | `kubectl logs <pod>` |

### Elastic Issues
| Error | Cause | Fix |
|-------|-------|-----|
| Elasticsearch yellow | Single replica (normal) | No fix needed |
| Elasticsearch red | Shard issues | Check cluster events |
| Kibana not ready | Waiting on ES | Wait for ES to be green |
| Agents not connecting | Fleet Server issue | Check Fleet Server first |

### Kibana Access Issues
| Issue | Fix |
|-------|-----|
| Can't access kibana.elastic.internal | Use jumpbox RDP |
| "Secure connection required" | Use https:// not http:// |
| Certificate error | Expected - accept the self-signed cert |

## 3. Jumpbox Access Help

If the issue is accessing Kibana:

```
## Accessing Kibana via Jumpbox

1. Get the jumpbox IP:
   terraform output jumpbox_public_ip

2. Get the password:
   terraform output jumpbox_password_command
   # Run the command it shows to get the password

3. Connect via RDP:
   - Windows: Use Remote Desktop Connection
   - Mac: Use Microsoft Remote Desktop app
   - Username: Administrator
   - Password: (from step 2)

4. In the jumpbox browser, go to:
   https://kibana.elastic.internal

5. Login:
   - Username: elastic
   - Password: kubectl get secret logs-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d
```

## 4. Present Findings

```
## Diagnostic Results

### What I Found
{Summary of the issue}

### The Problem
{Clear explanation of what's wrong}

### How to Fix It

{Step-by-step fix}

Want me to help you run these commands?
```

## 5. Common Quick Fixes

If you identify a common issue, offer to fix it directly:

```
This is a common issue. I can fix it by running:

{command}

Should I go ahead?
```

Wait for confirmation before running fixes.

## 6. Phase-Specific Troubleshooting

### Phase 1-2: Infrastructure
- Check AWS credentials are working
- Verify terraform state isn't locked
- Ensure EKS cluster is ready

### Phase 3-4: ECK Stack
- Check ECK operator is running: `kubectl get pods -n elastic-system -l control-plane=elastic-operator`
- Verify PVCs are bound: `kubectl get pvc -n elastic-system`
- Check resource constraints: `kubectl describe pod <pending-pod> -n elastic-system`

### Phase 5: APM
- Ensure APM policy is created in Fleet
- Check APM agent pod logs

### Phase 6: ML & ELSER
- Verify ML node has enough memory (needs 4GB+)
- Check if ML node tolerations match the node taints
- ELSER download may take a few minutes

### Phase 7: AI Assistant
- Verify Bedrock access is working
- Check connector configuration in Kibana

## 7. If Can't Diagnose

```
I'm not immediately seeing what's wrong. Let's dig deeper:

1. What were you trying to do when it failed?
2. What error message did you see?
3. Can you paste the full output?

With more details, I can help you figure this out.
```

## 8. Escalation

If the issue seems complex:

```
This looks like it might need some manual investigation.

Here's what I'd suggest:
1. {First thing to try}
2. {Second thing to try}
3. Check the Instruqt challenge hints for common issues

You can also ask your workshop instructor for help with this specific issue.
```
