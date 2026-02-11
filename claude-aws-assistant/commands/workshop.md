# /workshop - Start or Resume the ECK Workshop

When the user runs `/workshop`, do the following:

## 1. Check for Existing State

Read `.workshop-state.json`. If it exists and has `currentPhase > 0`, the student is resuming.

## 2. If Resuming (state file exists with progress)

Greet them back warmly:
```
Welcome back to the ECK Workshop!

You're currently on Phase {currentPhase}: {phase name}.
Last activity: {lastActivity}

Would you like to:
1. Continue where you left off
2. See your full progress so far
3. Start over from the beginning (this will reset your progress)

Just let me know and we'll pick up from there!
```

Wait for their response before proceeding.

## 3. If New (no state file or currentPhase is 0)

Update the state file to mark the start:

```json
{
  "currentPhase": 1,
  "completedSteps": [],
  "startedAt": "<current ISO timestamp>",
  "lastActivity": "<current ISO timestamp>",
  "studentConfig": {
    "clusterName": "<from TF_VAR_cluster_name>"
  }
}
```

Then deliver this welcome message:

```
# Welcome to the ECK on AWS Workshop!

I'm excited to guide you through deploying a production-grade Elastic Stack
on Amazon EKS. By the end of this workshop, you'll have hands-on experience
with modern cloud infrastructure and observability.

## What We're Building

**Infrastructure Layer:**
- VPC (Virtual Private Cloud) - Your isolated network in AWS
- EKS Cluster - Managed Kubernetes where our apps run
- Node Groups - EC2 instances powering the cluster
- Windows Jumpbox - RDP access to internal resources

**Observability Stack:**
- Elasticsearch - Search and analytics engine for all your data
- Kibana - Web UI for exploring and visualizing
- Fleet Server - Centrally manages log collection agents
- Elastic Agents - Ship logs from every node
- APM Server - Application Performance Monitoring
- ELSER - Semantic search with ML

## The 8 Phases

| Phase | Challenge | What You'll Do |
|-------|-----------|----------------|
| 1 | Environment Setup | Configure AWS credentials |
| 2 | Deploy Infrastructure | Deploy VPC + EKS cluster |
| 3 | Deploy ECK Stack | Deploy ES, Kibana, Gateway |
| 4 | Fleet & Monitoring | Deploy Fleet Server + Agents |
| 5 | APM & Observability | Deploy APM + OTel Demo |
| 6 | ML & ELSER | Add ML nodes, deploy ELSER |
| 7 | AI Assistant | Configure LLM connector |
| 8 | Exploration | Free exploration |

## Helpful Commands

At any point, you can use these commands:
- `/status` - See where you are in the workshop
- `/verify` - Check if your current phase is complete
- `/troubleshoot` - Get help diagnosing issues
- `/cleanup` - Tear down all resources when done

## Let's Get Started!

Ready to begin? I'll walk you through each step, explaining what we're doing
and why along the way.

Let's dive into Phase 1!
```

## 4. Begin Phase 1: Environment Setup

Transition into Phase 1:

```
---

# Phase 1: Environment Setup

Before we deploy to AWS, let's verify your environment is configured correctly.

## What We Need

1. **AWS Credentials** - Access to the shared AWS account
2. **Environment Variables** - Cluster name and region set
3. **Required Tools** - AWS CLI, terraform, kubectl, helm

Let me check your environment...
```

### Check Environment

```bash
# Source the workshop environment
source /root/.workshop-env

# Verify AWS credentials
aws sts get-caller-identity

# Check cluster name is set
echo "Cluster name: $TF_VAR_cluster_name"
```

### Verify Tools

Check each tool:
- `aws --version`
- `terraform --version`
- `kubectl version --client`
- `helm version`

### Complete Phase 1

Once verified:

```
---

## Phase 1 Complete!

Your environment is ready:

| Check | Status |
|-------|--------|
| AWS Credentials | Ready |
| Cluster Name | {cluster_name} |
| AWS CLI | v{version} |
| Terraform | v{version} |
| kubectl | v{version} |
| Helm | v{version} |

**Next up: Phase 2 - Deploy Infrastructure**

We'll create the VPC and EKS cluster. This takes about 15-20 minutes.

Ready to continue?
```

Update the state file:
- Set `currentPhase` to 2
- Add "phase-1-environment" to `completedSteps`
- Update `lastActivity`

Then proceed to Phase 2 guidance.
