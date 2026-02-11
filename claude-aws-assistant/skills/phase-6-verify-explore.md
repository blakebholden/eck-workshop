# Skill: Phase 6 - Verify & Explore

Load this skill when guiding students through the final phase of the workshop.

## Overview

This phase is the payoff! Students will:
1. Access Kibana through port-forwarding
2. Log in and explore the interface
3. See logs flowing from their cluster
4. (Optional) Deploy sample applications
5. Use Discover to search logs

---

## Step-by-Step Guide

### Step 1: Get Kibana Credentials

First, retrieve the Elasticsearch password:

```bash
ELASTIC_PASSWORD=$(kubectl get secret logs-es-elastic-user -n elastic-system \
  -o jsonpath='{.data.elastic}' | base64 -d)

echo "========================================="
echo "Kibana Login Credentials"
echo "========================================="
echo "Username: elastic"
echo "Password: $ELASTIC_PASSWORD"
echo "========================================="
```

**Explain:**
```
ECK automatically generates a secure password for the 'elastic' superuser
and stores it in a Kubernetes Secret. We're extracting it here.

The password is base64-encoded in the secret, so we decode it.
Save this password - you'll need it to log into Kibana!
```

---

### Step 2: Port-Forward to Kibana

Open a tunnel to Kibana:

```bash
kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601
```

**Explain:**
```
Since Kibana is running inside the cluster, we need a way to access it
from your laptop. Port-forwarding creates a secure tunnel:

  Your laptop:5601  ──tunnel──▶  Kibana Service:5601

This is great for development and workshops. In production, you'd use
an Ingress or LoadBalancer for proper external access.

Keep this terminal window open - the port-forward runs until you stop it.
```

**Note:** This command blocks the terminal. Students should open a new terminal or run in background.

---

### Step 3: Access Kibana

Open a web browser and navigate to:

```
https://localhost:5601
```

**Explain:**
```
You'll likely see a security warning about the certificate. This is
expected - ECK generates a self-signed certificate for internal use.

Click "Advanced" and "Proceed to localhost" (or similar depending on
your browser).

In production, you'd configure a proper certificate from a CA.
```

**Login:**
- Username: `elastic`
- Password: (the password from Step 1)

---

### Step 4: Initial Kibana Setup

After logging in, you may see a welcome screen. Guide them through:

```
When Kibana loads, you'll see the home screen. Let me show you around:

1. **Home** - Quick links to common features
2. **Discover** - Search and explore your logs (we'll use this!)
3. **Dashboard** - Pre-built visualizations
4. **Observability** - Logs, metrics, and APM in one place
5. **Fleet** - Manage your agents

First, let's check that Fleet is connected properly.
```

---

### Step 5: Verify Fleet & Agents

Navigate to Fleet:

1. Click the hamburger menu (☰) in the top left
2. Go to **Management** → **Fleet**

**What to look for:**
```
In Fleet, you should see:

1. **Fleet Server** - Status should be "Healthy"
2. **Agents** - You should see agents for each Kubernetes node
   - Status: "Healthy"
   - Last activity: Recent timestamp

If you see your agents here, data is flowing!
```

---

### Step 6: Explore Logs in Discover

Now let's see the actual logs:

1. Click the hamburger menu (☰)
2. Go to **Analytics** → **Discover**
3. In the data view dropdown (top left), select `logs-*`

**Explain:**
```
Discover is where you search and explore your logs. The logs-* pattern
matches all indices that start with "logs-".

What you're seeing:
- **Timeline histogram** - Log volume over time
- **Documents** - Individual log entries
- **Fields** - Available fields to filter/search on

Try expanding a log entry to see all the fields!
```

---

### Step 7: Search and Filter

Show them how to search:

```
Let's try some searches. In the search bar at the top:

1. **Search for a namespace:**
   kubernetes.namespace : "kube-system"

2. **Search for errors:**
   log.level : "error" OR message : "error"

3. **Search for a specific pod:**
   kubernetes.pod.name : "coredns*"

Click on field names in the left sidebar to see common values
and filter by them.
```

---

### Step 8: (Optional) Deploy Sample Applications

If enabled in the terraform variables:

```bash
# In a new terminal (keep port-forward running!)

# Check if sample apps are deployed
kubectl get pods -n sample-apps

# If not deployed, check terraform
terraform output -json | jq .sample_apps_enabled
```

**If sample apps are running:**
```
The sample apps generate interesting log data. Let's see them:

In Discover, search for:
  kubernetes.namespace : "sample-apps"

You should see logs from the demo applications!
```

---

### Step 9: Create a Quick Visualization

Walk through creating a simple visualization:

1. Click **Visualize Library** (or Analytics → Visualize)
2. Click **Create new visualization**
3. Select **Lens** (easiest option)
4. Drag `@timestamp` to the X-axis
5. Choose **Count** for the Y-axis
6. Drag `kubernetes.namespace` to **Break down by**

**Explain:**
```
This creates a chart showing log volume by namespace over time.
You can see which namespaces are generating the most logs!

Lens makes it easy to create visualizations by dragging and dropping
fields. No query language needed.
```

---

### Step 10: Explore Observability Features

Show the Observability section:

1. Click hamburger menu (☰)
2. Go to **Observability** → **Logs** → **Stream**

```
The Log Stream shows logs in real-time as they come in. This is
great for live debugging - you can watch logs appear as events happen.

Try generating some activity:

# In another terminal
kubectl get pods --all-namespaces

Then watch the log stream for kubectl-related activity!
```

---

### Step 11: Access via Windows Jumpbox (Optional)

If the jumpbox was deployed, you can access Kibana through a browser inside the VPC instead of using port-forwarding.

**Why use the Jumpbox?**
```
The jumpbox is a Windows EC2 instance inside your VPC. Because it's
INSIDE the VPC, it can:

- Resolve private DNS names (kibana.elastic.internal)
- Access the internal load balancer directly
- Use a real browser without port-forwarding

This is how you'd access private services in a real production environment.
```

#### Get Jumpbox Connection Info

```bash
# Get the jumpbox public IP
terraform output jumpbox_public_ip

# Get the Administrator password
terraform output jumpbox_password
```

**Note**: The password is auto-generated and stored in AWS Secrets Manager. The terraform output retrieves it for you.

#### Connect via RDP

**On Mac:**
1. Download Microsoft Remote Desktop from the App Store
2. Click "+" → "Add PC"
3. Enter the jumpbox public IP
4. Connect with:
   - Username: `Administrator`
   - Password: (from terraform output)

**On Windows:**
1. Open Remote Desktop Connection (mstsc.exe)
2. Enter the jumpbox public IP
3. Login with Administrator credentials

#### Access Kibana from Jumpbox

Once connected to the jumpbox:

1. Open **Microsoft Edge** (or install Chrome)
2. Navigate to: `https://kibana.elastic.internal`
3. Accept the self-signed certificate warning
4. Login with:
   - Username: `elastic`
   - Password: (the password you retrieved earlier)

```
The jumpbox can resolve kibana.elastic.internal because:
- It's inside the VPC
- Route53 Private Hosted Zone is associated with the VPC
- The DNS resolves to the internal NLB

From your laptop, this DNS name doesn't resolve because you're
outside the VPC!
```

#### Jumpbox Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                   │
│                                                                  │
│  ┌──────────────┐                    ┌──────────────────────┐   │
│  │   Jumpbox    │                    │    EKS Cluster       │   │
│  │  (Windows)   │                    │                      │   │
│  │              │ ──── Private ────▶ │  ┌────────────────┐  │   │
│  │  Public IP   │       DNS          │  │     Kibana     │  │   │
│  │  for RDP     │                    │  └────────────────┘  │   │
│  └──────────────┘                    └──────────────────────┘   │
│         ▲                                                        │
│         │                                                        │
└─────────┼────────────────────────────────────────────────────────┘
          │
          │ RDP (port 3389)
          │
    ┌─────┴─────┐
    │   Your    │
    │  Laptop   │
    └───────────┘

Traffic Flow:
1. You RDP to jumpbox (over internet, port 3389)
2. Jumpbox browser requests kibana.elastic.internal
3. Private DNS resolves to internal NLB
4. NLB routes to Kibana pod
5. Kibana responds back
```

#### Jumpbox Troubleshooting

**Can't connect via RDP:**
```bash
# Check the jumpbox is running
aws ec2 describe-instances --filters "Name=tag:Name,Values=*jumpbox*" \
  --query "Reservations[].Instances[].{State:State.Name,IP:PublicIpAddress}"

# Check security group allows RDP
aws ec2 describe-security-groups --filters "Name=group-name,Values=*jumpbox*" \
  --query "SecurityGroups[].IpPermissions[?FromPort==\`3389\`]"
```

**DNS not resolving inside jumpbox:**
```
# Open PowerShell on the jumpbox and run:
nslookup kibana.elastic.internal

# Should return the NLB IP address
# If it fails, the Route53 Private Hosted Zone may not be ready
```

**Can't reach Kibana from jumpbox:**
```
# Test connectivity to the NLB
Test-NetConnection -ComputerName kibana.elastic.internal -Port 443

# If this fails, check the NLB is provisioned:
# (from your laptop)
kubectl get gateway -n elastic-system
```

---

## Summary

```bash
# Get credentials
kubectl get secret logs-es-elastic-user -n elastic-system \
  -o jsonpath='{.data.elastic}' | base64 -d

# Port-forward to Kibana
kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601

# Access Kibana
# Open: https://localhost:5601
# Login: elastic / <password>
```

---

## Troubleshooting

### Can't connect to localhost:5601

**Cause**: Port-forward died or wrong port.

**Fix**:
```bash
# Check for existing port-forward
lsof -i :5601

# Restart port-forward
kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601
```

### "Kibana server is not ready yet"

**Cause**: Kibana still starting or can't reach Elasticsearch.

**Fix**:
```bash
kubectl get kibana -n elastic-system
kubectl logs -n elastic-system -l kibana.k8s.elastic.co/name=kibana --tail=50
```

### No data in Discover

**Cause**: Data view not configured or agents not shipping data.

**Fix**:
1. Make sure you selected `logs-*` data view
2. Adjust time range (top right) to "Last 1 hour"
3. Check Fleet to see if agents are healthy

### Password doesn't work

**Cause**: Might have copied extra characters.

**Fix**:
```bash
# Print password without newline
kubectl get secret logs-es-elastic-user -n elastic-system \
  -o jsonpath='{.data.elastic}' | base64 -d && echo ""
```

---

## What Success Looks Like

Phase 6 is complete when:
1. ✓ Successfully logged into Kibana (via port-forward OR jumpbox)
2. ✓ Fleet shows healthy agents
3. ✓ Discover shows log data
4. ✓ Can search and filter logs
5. ✓ Understands basic Kibana navigation
6. ✓ (Optional) Connected via jumpbox and accessed private DNS

---

## Workshop Complete! 🎉

```
Congratulations! You've completed the ECK on AWS Workshop!

Let's recap what you've accomplished:

## What You Built
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud (us-east-2)                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                     Your VPC                            │ │
│  │                                                         │ │
│  │  ┌──────────┐   ┌─────────────────────────────────┐   │ │
│  │  │ Jumpbox  │   │         EKS Cluster              │   │ │
│  │  │(Windows) │   │                                  │   │ │
│  │  │          │──▶│  ┌────────────┐  ┌───────────┐  │   │ │
│  │  │ RDP in   │   │  │Elasticsearch│  │  Kibana   │  │   │ │
│  │  └──────────┘   │  └────────────┘  └───────────┘  │   │ │
│  │                 │                                  │   │ │
│  │  ┌──────────┐   │  ┌────────────┐  ┌───────────┐  │   │ │
│  │  │   NLB    │──▶│  │Fleet Server│  │  Agents   │  │   │ │
│  │  │(Gateway) │   │  └────────────┘  └───────────┘  │   │ │
│  │  └──────────┘   └─────────────────────────────────┘   │ │
│  │                                                        │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │    Route53 Private DNS (*.elastic.internal)     │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

## Skills You Learned
- ✓ AWS CLI authentication and profiles (eck-workshop)
- ✓ Terraform infrastructure as code
- ✓ EKS cluster creation and kubectl access
- ✓ Gateway API and Envoy for ingress
- ✓ ECK for Elastic Stack on Kubernetes
- ✓ Kibana for log visualization
- ✓ Private DNS and VPC networking
- ✓ Windows jumpbox for private resource access

## What's Next?
- Add more integrations (APM, Metrics, Uptime)
- Create custom dashboards for your use case
- Set up alerting for important events
- Scale Elasticsearch for production workloads

## Important Reminders
- This deployment costs money while running!
- When you're done exploring, run `/cleanup` to tear everything down
- Your Elasticsearch data will be lost when you destroy the cluster

Thank you for participating in this workshop! 🙌
```

---

## Post-Workshop: Cleanup Reminder

After students have explored, remind them:

```
⚠️  DON'T FORGET TO CLEAN UP!

AWS resources cost money while running. When you're done exploring:

1. Stop the port-forward (Ctrl+C)
2. Run /cleanup for guided teardown

Or manually:
  cd terraform
  terraform destroy -var-file="my-workshop.tfvars"

This will delete ALL resources and stop charges.
```
