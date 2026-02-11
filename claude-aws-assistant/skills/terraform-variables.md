# Skill: Terraform Variables Configuration

Load this skill when students need to customize their Terraform variables, especially `cluster_name` to ensure unique resources in the shared AWS environment.

## Why This Matters

In this workshop, all students share the same AWS account with administrator permissions. Each student creates their own:
- VPC (with unique naming)
- EKS cluster (must have unique name)
- Elastic Stack deployment

**The `cluster_name` variable is CRITICAL** - it must be unique per student to avoid conflicts.

---

## Step-by-Step Guide

### Step 1: Navigate to Terraform Directory

```bash
cd terraform
```

---

### Step 2: Create a Personal tfvars File

Each student should create their own variables file. This keeps their configuration separate and makes it easy to customize.

```bash
# Create a personal tfvars file
touch my-workshop.tfvars
```

---

### Step 3: Set a Unique Cluster Name

**This is the most important step.** The cluster name must be unique across all students.

**Recommended naming convention**: `eck-<your-name>` or `eck-<initials>-<number>`

Examples:
- `eck-alice`
- `eck-bob-01`
- `eck-jsmith`

Write the following to your tfvars file:

```hcl
# my-workshop.tfvars

# REQUIRED: Change this to something unique!
cluster_name = "eck-<YOUR-NAME>"

# Optional: Change region if needed (default is us-east-2)
# region = "us-west-2"

# Optional: Add your name/email for resource tagging
# project = "eck-workshop-alice"
```

**Example for a student named Alice:**

```hcl
cluster_name = "eck-alice"
project      = "eck-workshop-alice"
```

---

### Step 4: Verify Your Configuration

Check that the file looks correct:

```bash
cat my-workshop.tfvars
```

**Expected output:**
```hcl
cluster_name = "eck-alice"
```

---

### Step 5: Test with Terraform Plan

Before deploying, run a plan to verify your configuration:

```bash
terraform plan -var-file="my-workshop.tfvars"
```

**Look for these key resources with your unique name:**
- `module.eks.aws_eks_cluster.this[0]` will show `name = "eck-alice"`
- VPC resources will be tagged with your cluster name

---

## Using Your Variables File

**IMPORTANT**: For ALL terraform commands, you must specify your tfvars file:

```bash
# Initialize (no tfvars needed)
terraform init

# Plan with your variables
terraform plan -var-file="my-workshop.tfvars"

# Apply with your variables
terraform apply -var-file="my-workshop.tfvars"

# Destroy with your variables
terraform destroy -var-file="my-workshop.tfvars"
```

---

## Available Variables

Here are the key variables you can customize:

| Variable | Default | Description | Should You Change? |
|----------|---------|-------------|-------------------|
| `cluster_name` | `eck-demo` | EKS cluster name | **YES - REQUIRED** |
| `region` | `us-east-2` | AWS region | Only if instructor specifies |
| `environment` | `dev` | Environment tag | Optional |
| `project` | `eck` | Project tag | Recommended - add your name |
| `kubernetes_version` | `1.29` | K8s version | No - leave default |
| `elastic_version` | `9.2.4` | Elastic version | No - leave default |

### Feature Flags

These are enabled by default. You can disable to save time/resources:

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_monitoring_cluster` | `true` | Separate monitoring ES cluster |
| `enable_sample_apps` | `true` | Demo applications |
| `enable_apm` | `true` | APM Server |
| `enable_logstash` | `true` | Logstash |
| `enable_jumpbox` | `true` | Windows RDP jumpbox |
| `enable_gateway_api` | `true` | Envoy Gateway + private DNS |

**For faster deployment**, you can disable optional components:

```hcl
# my-workshop.tfvars - minimal deployment

cluster_name = "eck-alice"

# Disable optional components for faster deployment
enable_monitoring_cluster = false
enable_sample_apps        = false
enable_apm                = false
enable_logstash           = false
enable_jumpbox            = false
enable_gateway_api        = false
```

---

## Checking for Conflicts

Before deploying, check if your cluster name is already in use:

```bash
aws eks list-clusters --region us-east-2
```

If you see your chosen name in the list, pick a different one.

---

## Common Issues

### "Cluster with name already exists"

**Cause**: Another student used the same cluster name.

**Fix**: Choose a more unique name:
```hcl
cluster_name = "eck-alice-workshop-2024"
```

### "Forgot to use -var-file"

**Symptoms**: Resources created with default name `eck-demo` instead of your custom name.

**Fix**: Always use `-var-file`:
```bash
# Wrong
terraform apply

# Right
terraform apply -var-file="my-workshop.tfvars"
```

### "VPC CIDR conflict"

This shouldn't happen since each student creates their own VPC. But if it does:

```hcl
# Change CIDR block (use a different /16)
vpc_cidr = "10.1.0.0/16"  # Instead of default 10.0.0.0/16
```

---

## Quick Reference

```bash
# Create your config
cat > my-workshop.tfvars << 'EOF'
cluster_name = "eck-YOUR-NAME"
project      = "eck-workshop-YOUR-NAME"
EOF

# Always use your config file
terraform plan -var-file="my-workshop.tfvars"
terraform apply -var-file="my-workshop.tfvars"

# Check existing clusters
aws eks list-clusters --region us-east-2

# View your config
cat my-workshop.tfvars
```

---

## What Success Looks Like

After configuration, `terraform plan -var-file="my-workshop.tfvars"` should show:
- Your unique cluster name in resource names
- Your project tag in resource tags
- No conflicts with existing resources
