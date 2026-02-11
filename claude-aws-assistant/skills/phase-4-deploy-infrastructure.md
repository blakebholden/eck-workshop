# Skill: Phase 4 - Deploy VPC & EKS Infrastructure

Load this skill when guiding students through Phase 4 of the workshop.

## Overview

This phase deploys the foundational AWS infrastructure:
1. **VPC** - Virtual Private Cloud with subnets, NAT gateways, and routing
2. **EKS** - Elastic Kubernetes Service cluster with managed node groups
3. **Envoy Gateway Base** - Start the load balancer provisioning early (saves time later!)

This is the longest phase (~15-20 minutes total), primarily due to EKS cluster creation.

---

## CRITICAL: Always Wait for Confirmation

**Before EVERY terraform command, you MUST:**
1. Explain what will happen
2. Show the command
3. Ask: "Ready to run this? (**yes** / **no** / **tell me more**)"
4. **WAIT for the student to respond before running**

**DO NOT auto-run terraform commands!**

---

## Step-by-Step Guide

### Step 1: Verify Prerequisites

Before deploying, confirm:

```bash
# Still in terraform directory?
pwd

# AWS credentials working with eck-workshop profile?
aws sts get-caller-identity

# Terraform initialized?
ls .terraform/providers
```

**Ask:** "All prerequisites look good? (**yes** / **no** / **tell me more**)"

**WAIT for response.**

---

### Step 2: Deploy VPC (WAIT FOR CONFIRMATION)

**Explain the strategy:**
```
We're going to deploy in stages rather than all at once. This makes it
easier to troubleshoot if something goes wrong, and lets you see the
infrastructure come up piece by piece.

First up: the VPC (Virtual Private Cloud). This is your isolated network
in AWS - like having your own private data center in the cloud.
```

**Show the command:**
```
**Tool**: Terraform - Infrastructure as Code

**Command**: `terraform apply -target=module.vpc -var-file="my-workshop.tfvars"`

**What it does**: Creates your Virtual Private Cloud with:
- Public and private subnets across availability zones
- Internet Gateway for public access
- NAT Gateway for private subnet internet access
- Route tables for traffic routing

**Why it matters**: The VPC is the foundation - your EKS cluster needs
a network to run in. Without this, nothing else can be deployed.

**Expected output**: "Apply complete! Resources: ~15 added"
```

**Ask:** "Ready to deploy the VPC? (**yes** / **no** / **tell me more**)"

**⚠️ WAIT FOR STUDENT TO SAY YES BEFORE RUNNING! ⚠️**

---

After student confirms, run:
```bash
terraform apply -target=module.vpc -var-file="my-workshop.tfvars"
```

Terraform will show a plan and ask for confirmation. Type `yes`.

**Expected duration**: ~2-3 minutes

**After completion, explain:**
```
The VPC module created:

1. **VPC** - Your isolated network (CIDR: 10.0.0.0/16)
2. **Subnets** - Public (for load balancers) and Private (for EKS nodes)
3. **Internet Gateway** - Allows public subnet traffic to/from internet
4. **NAT Gateway** - Lets private resources reach internet (one-way)
5. **Route Tables** - Traffic routing rules
```

**Ask:** "VPC is ready! Ready for the next step? (**yes** / **no** / **tell me more**)"

**WAIT for response.**

---

### Step 3: Deploy EKS Cluster (WAIT FOR CONFIRMATION)

**Explain:**
```
Now for the main event: EKS (Elastic Kubernetes Service).

EKS is AWS's managed Kubernetes offering. AWS handles:
- The control plane (API server, etcd, scheduler)
- Kubernetes version upgrades
- High availability across AZs

You manage:
- The worker nodes (EC2 instances)
- What runs on the cluster

⏱️ This takes about 15 minutes because AWS is provisioning a highly
available control plane across multiple data centers.
```

**Show the command:**
```
**Tool**: Terraform

**Command**: `terraform apply -target=module.eks -var-file="my-workshop.tfvars"`

**What it does**: Creates your Kubernetes cluster:
- EKS control plane (managed by AWS)
- Managed node group with EC2 instances
- IAM roles and security groups
- Kubernetes add-ons (CoreDNS, kube-proxy, VPC CNI)

**Why it matters**: This is where all your applications will run.
Kubernetes orchestrates containers across the cluster.

**Expected output**: "Apply complete! Resources: ~25 added" (after ~15 min)
```

**Ask:** "Ready to deploy EKS? This will take about 15 minutes. (**yes** / **no** / **tell me more**)"

**⚠️ WAIT FOR STUDENT TO SAY YES BEFORE RUNNING! ⚠️**

---

After student confirms, run:
```bash
terraform apply -target=module.eks -var-file="my-workshop.tfvars"
```

Type `yes` when prompted.

**While waiting (~15 minutes), explain the architecture:**

```
## What's Happening Behind the Scenes

┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Your VPC                              ││
│  │                                                          ││
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ││
│  │  │  Private     │  │  Private     │  │  Public      │  ││
│  │  │  Subnet AZ-a │  │  Subnet AZ-b │  │  Subnets     │  ││
│  │  │              │  │              │  │  (LBs here)  │  ││
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │              │  ││
│  │  │  │EKS Node│  │  │  │EKS Node│  │  │              │  ││
│  │  │  └────────┘  │  │  └────────┘  │  │              │  ││
│  │  └──────────────┘  └──────────────┘  └──────────────┘  ││
│  │                           ▲                             ││
│  └───────────────────────────┼─────────────────────────────┘│
│                              │                               │
│  ┌───────────────────────────┼─────────────────────────────┐│
│  │        EKS Control Plane (AWS Managed)                  ││
│  │   ┌─────────┐  ┌─────────┐  ┌─────────┐                ││
│  │   │API Server│  │Scheduler│  │  etcd   │                ││
│  │   └─────────┘  └─────────┘  └─────────┘                ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

## Creation Timeline:

1. **Control Plane** (5 min) - API server, etcd, scheduler
2. **Networking** (3 min) - ENIs, VPC endpoints
3. **Node Group** (5 min) - EC2 instances joining cluster
4. **Add-ons** (2 min) - CoreDNS, kube-proxy, VPC CNI
```

**Check progress periodically:**
```bash
aws eks describe-cluster --name <cluster-name> --query "cluster.status" --output text
```

Status progression: `CREATING` → `ACTIVE`

---

### Step 4: Configure kubectl

After EKS completes:

**Show the command:**
```
**Tool**: AWS CLI

**Command**: `aws eks update-kubeconfig --name <cluster-name> --region us-east-2`

**What it does**: Configures kubectl to talk to your new cluster by
updating ~/.kube/config with the cluster endpoint and authentication.

**Why it matters**: Without this, kubectl won't know which cluster to manage.
```

**Ask:** "Ready to configure kubectl? (**yes** / **no** / **tell me more**)"

**WAIT**, then run:
```bash
aws eks update-kubeconfig --name <cluster-name> --region us-east-2
```

---

### Step 5: Verify Cluster Access

```bash
kubectl get nodes
```

**Expected output:**
```
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.us-east-2.compute.internal   Ready    <none>   5m    v1.29.x
ip-10-0-2-xxx.us-east-2.compute.internal   Ready    <none>   5m    v1.29.x
```

**Explain:**
```
You're now connected to your Kubernetes cluster!

- **STATUS: Ready** - Nodes are healthy and accepting workloads
- **ROLES: <none>** - Normal for worker nodes (control plane is managed)
- **VERSION** - Kubernetes version running on the nodes
```

---

### Step 6: Deploy Envoy Gateway Base (WAIT FOR CONFIRMATION)

**This step is important!** We deploy the gateway now so the Load Balancer
starts provisioning while we deploy ECK. Load balancers take 3-5 minutes.

**Explain:**
```
## Why Deploy the Gateway Now?

When you create a Kubernetes Ingress or Gateway, AWS needs to provision
a Load Balancer. This takes 3-5 minutes.

By starting this NOW (while we set up Elasticsearch), the Load Balancer
will be ready by the time we need it. This saves waiting time later!

We're using Envoy Gateway - a modern implementation of the Kubernetes
Gateway API. It's more flexible than traditional Ingress controllers.
```

**Show the command:**
```
**Tool**: Terraform

**Command**: `terraform apply -target=module.envoy_gateway_base -var-file="my-workshop.tfvars"`

**What it does**:
- Installs Envoy Gateway controller
- Creates a Gateway resource
- Starts provisioning a Network Load Balancer (NLB)

**Why it matters**: The NLB is how external traffic reaches your services.
Starting it now means less waiting later.

**Expected output**: "Apply complete!" (NLB continues provisioning in background)
```

**Ask:** "Ready to start the gateway provisioning? (**yes** / **no** / **tell me more**)"

**⚠️ WAIT FOR STUDENT TO SAY YES BEFORE RUNNING! ⚠️**

After confirmation:
```bash
terraform apply -target=module.envoy_gateway_base -var-file="my-workshop.tfvars"
```

**After completion:**
```
The Envoy Gateway is now deploying. The Load Balancer is being
provisioned in the background - this takes a few minutes but will
continue while we deploy the Elastic Stack.

You can check the gateway status anytime with:
  kubectl get gateway -n elastic-system
```

---

### Step 7: Verify Everything is Ready

```bash
# Check nodes
kubectl get nodes

# Check core pods
kubectl get pods -n kube-system

# Check gateway (may still be provisioning)
kubectl get gateway -A
```

---

## What Success Looks Like

Phase 4 is complete when:
1. ✓ VPC and networking created
2. ✓ EKS cluster is ACTIVE
3. ✓ kubectl configured and connected
4. ✓ Nodes showing "Ready"
5. ✓ Envoy Gateway base deployed (LB provisioning)

---

## Troubleshooting

### Terraform didn't wait for confirmation
If terraform started without you saying yes, remind the student that
terraform itself asks for confirmation ("Enter a value: yes"). The
workshop pauses are BEFORE showing the command.

### Nodes showing "NotReady"
Wait a few minutes. If still not ready:
```bash
kubectl describe node <node-name>
```

### "error: You must be logged in to the server"
```bash
export AWS_PROFILE=eck-workshop
aws sts get-caller-identity
aws eks update-kubeconfig --name <cluster-name> --region us-east-2
```

---

## Transition to Phase 5

```
Congratulations! You now have:
- ✓ A secure VPC with public and private subnets
- ✓ An EKS cluster with managed worker nodes
- ✓ Envoy Gateway with Load Balancer provisioning

This is production-grade infrastructure!

Next up: Phase 5 - Deploy the ECK Stack

We'll install the Elastic Stack:
- ECK Operator (manages Elastic resources)
- Elasticsearch (search and analytics engine)
- Kibana (visualization and UI)
- Fleet Server (agent management)
- Elastic Agents (log collection)

Ready to deploy the observability stack? (**yes** / **no** / **tell me more**)
```
