# /troubleshoot - Diagnose and Fix Issues

When the user runs `/troubleshoot`, help them debug their current situation.

## 1. Gather Context

First, understand where they are:

```
Let me check a few things to understand what's happening...
```

Run these diagnostic commands:

```bash
# Check AWS
aws sts get-caller-identity 2>&1

# Check if in right directory
ls ../terraform/*.tf 2>&1

# Check Kubernetes (if applicable)
kubectl get nodes 2>&1

# Check Elastic (if applicable)
kubectl get pods -n elastic-system 2>&1
```

## 2. Identify the Problem

Based on the output, categorize the issue:

### AWS Issues
- "Unable to locate credentials" → Guide through `aws configure`
- "ExpiredToken" → Need to refresh credentials
- "AccessDenied" → Permissions issue, check IAM
- Region issues → Check `aws configure get region`

### Terraform Issues
- "No configuration files" → Wrong directory
- "Error acquiring state lock" → Another process running or stale lock
- "Provider not found" → Need to run `terraform init`
- Resource errors → Read the specific error message

### Kubernetes Issues
- "connection refused" → kubectl not configured, run `aws eks update-kubeconfig`
- "nodes not found" → Cluster might not exist yet
- Pods in `Pending` → Check events with `kubectl describe pod`
- Pods in `CrashLoopBackOff` → Check logs with `kubectl logs`

### Elastic Issues
- Elasticsearch yellow/red → Check cluster events and pod logs
- Kibana not ready → Usually waiting on Elasticsearch
- Agents not connecting → Check Fleet Server status first

## 3. Present Findings

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

## 4. Common Quick Fixes

If you identify a common issue, offer to fix it directly:

```
This is a common issue. I can fix it by running:

{command}

Should I go ahead?
```

Wait for confirmation before running fixes.

## 5. If Can't Diagnose

```
I'm not immediately seeing what's wrong. Let's dig deeper:

1. What were you trying to do when it failed?
2. What error message did you see?
3. Can you paste the full output?

With more details, I can help you figure this out.
```

## 6. Escalation

If the issue seems complex:

```
This looks like it might need some manual investigation.

Here's what I'd suggest:
1. {First thing to try}
2. {Second thing to try}
3. If those don't work, check the docs at ../docs/implementation-guide.md

You can also ask your workshop instructor for help with this specific issue.
```
