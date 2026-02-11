# /workshop - Start or Resume the ECK Workshop

When the user runs `/workshop`, do the following:

## 1. Check for Existing State

Read `claude-aws-assistant/.workshop-state.json`. If it exists and has `currentPhase > 0`, the student is resuming.

## 2. If Resuming (state file exists with progress)

Greet them back warmly:
```
Welcome back! Great to see you again.

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
  "lastActivity": "<current ISO timestamp>"
}
```

Then deliver this welcome message - be warm, enthusiastic, and set the stage:

```
# Welcome to the ECK on AWS Workshop!

I'm excited to guide you through deploying a production-grade observability
stack on Amazon Web Services. By the end of this workshop, you'll have
hands-on experience with some of the most important tools in modern
cloud infrastructure.

## What We're Building

We're going to deploy the **Elastic Stack** (formerly known as the ELK Stack)
on **Amazon EKS** (Elastic Kubernetes Service). Here's what that means:

**The Infrastructure Layer:**
- **VPC (Virtual Private Cloud)** - Your own isolated network in AWS
- **EKS Cluster** - A managed Kubernetes cluster where our apps will run
- **Node Groups** - The actual EC2 instances that power the cluster

**The Observability Layer:**
- **Elasticsearch** - A powerful search and analytics engine that stores all your logs
- **Kibana** - A beautiful web UI for exploring and visualizing your data
- **Fleet Server** - Centrally manages all your log collection agents
- **Elastic Agents** - Lightweight collectors that ship logs from every node

## What You'll Learn

By the end of this workshop, you'll understand:
- How to authenticate with AWS from the command line
- How Terraform provisions cloud infrastructure as code
- How Kubernetes orchestrates containerized applications
- How the Elastic Stack collects, stores, and visualizes logs

## The 6 Phases

We'll work through this step by step:

| Phase | What We Do | Time |
|-------|------------|------|
| 1. Prerequisites | Verify your tools are installed | ~5 min |
| 2. AWS Credentials | Configure access to AWS | ~5 min |
| 3. Terraform Init | Initialize the project | ~2 min |
| 4. Deploy VPC & EKS | Create the Kubernetes cluster | ~15 min |
| 5. Deploy ECK Stack | Install Elasticsearch, Kibana, Fleet | ~10 min |
| 6. Verify & Explore | See your logs in Kibana | ~10 min |

**Total time: approximately 45-50 minutes**

## Helpful Commands

At any point, you can use these commands:
- `/status` - See where you are in the workshop
- `/verify` - Check if your current phase is complete
- `/troubleshoot` - Get help diagnosing issues
- `/cleanup` - Tear down all resources when you're done

## Let's Get Started!

Ready to begin? I'll walk you through each step, explaining what we're doing
and why along the way. You'll run the commands, and I'll help interpret the
results.

Let's dive into Phase 1!
```

## 4. Begin Phase 1: Prerequisites

Transition into Phase 1 with context:

```
---

# Phase 1: Prerequisites

Before we can deploy anything to AWS, we need to make sure your local
machine has the right tools installed. Think of these as your toolkit
for cloud engineering.

We need four tools:

1. **AWS CLI** - Amazon's command-line interface for talking to AWS services
2. **Terraform** - HashiCorp's infrastructure-as-code tool
3. **kubectl** - The Kubernetes command-line tool
4. **Helm** - A package manager for Kubernetes

Let me check each one. I'll explain what each tool does as we verify it.
```

### Check AWS CLI

Explain first:
```
**AWS CLI (Amazon Web Services Command Line Interface)**

This is your primary way to interact with AWS from the terminal. Almost
everything we do with AWS - creating networks, launching clusters,
managing permissions - can be done through this tool.

The AWS CLI translates your commands into API calls to AWS services.
When you run `aws ec2 describe-instances`, for example, it's calling
the EC2 API on your behalf.

Let me check if it's installed...
```

Then run: `aws --version`

**If installed**:
```
Excellent! You have AWS CLI version {version} installed.

Quick note: We're using AWS CLI v2, which has better performance and
features than v1. Your version looks good!

Moving on to the next tool...
```

**If not installed**:
```
The AWS CLI isn't installed yet. No problem - let's fix that.

Run this command to install it via Homebrew:

    brew install awscli

Homebrew will download and install the latest version. This usually
takes about a minute.
```

Wait for install, then verify again.

### Check Terraform

Explain first:
```
**Terraform by HashiCorp**

Terraform is an "infrastructure as code" tool. Instead of clicking
around in the AWS console to create resources, we write configuration
files that describe what we want, and Terraform makes it happen.

Why is this better?
- **Reproducible**: Run the same code, get the same infrastructure
- **Version controlled**: Track changes in Git like any other code
- **Collaborative**: Teams can review infrastructure changes in PRs

In this workshop, all our AWS resources are defined in `.tf` files
in the `terraform/` directory.

Let me check if Terraform is installed...
```

Then run: `terraform --version`

Handle installed/not installed similarly to AWS CLI.
Use `brew install terraform` if missing.

### Check kubectl

Explain first:
```
**kubectl (Kubernetes Control)**

Pronounced "kube-control" or "kube-cuddle" (yes, really - the community
is divided!), this is the command-line tool for interacting with
Kubernetes clusters.

Once our EKS cluster is running, kubectl is how we'll:
- Deploy applications
- Check on running pods
- View logs
- Debug issues

It communicates with the Kubernetes API server to manage your cluster.

Let me check if it's installed...
```

Then run: `kubectl version --client`

Handle accordingly. Use `brew install kubectl` if missing.

### Check Helm

Explain first:
```
**Helm - The Package Manager for Kubernetes**

If kubectl is like apt-get for your cluster, Helm is like a
higher-level package manager that installs entire applications.

A "Helm chart" is a bundle of Kubernetes manifests that work together.
Instead of deploying 10 separate YAML files, you install one chart
and Helm handles the rest.

We use Helm in this workshop to install the ECK (Elastic Cloud on
Kubernetes) operator, which then manages our Elasticsearch cluster.

Let me check if it's installed...
```

Then run: `helm version`

Handle accordingly. Use `brew install helm` if missing.

## 5. Complete Phase 1

Once all four tools are verified:

```
---

## Phase 1 Complete! ✓

Excellent work! You now have all the tools you need:

| Tool | Version | Status |
|------|---------|--------|
| AWS CLI | {version} | ✓ Ready |
| Terraform | {version} | ✓ Ready |
| kubectl | {version} | ✓ Ready |
| Helm | {version} | ✓ Ready |

These four tools are the foundation of modern cloud infrastructure work.
You'll use them constantly in DevOps and platform engineering roles.

**Next up: Phase 2 - AWS Credentials**

We need to configure your terminal to authenticate with AWS. This is
where we'll set up your access keys and make sure you can actually
talk to AWS services.

Ready to continue?
```

Update the state file:
- Set `currentPhase` to 2
- Add "phase-1-prerequisites" to `completedSteps`
- Update `lastActivity`

Then proceed to Phase 2 guidance (load the phase-2-aws-credentials skill for detailed instructions).
