# Skill: Phase 3 - Terraform Initialization

Load this skill when guiding students through Phase 3 of the workshop.

## Overview

In this phase, students initialize Terraform, which downloads required providers and prepares the working directory. We also help them configure their unique variables file.

---

## Step-by-Step Guide

### Step 1: Navigate to Terraform Directory

```bash
cd terraform
```

**Explain:**
```
We're moving into the terraform/ directory where all our infrastructure
code lives. This is where you'll run all Terraform commands from.
```

**Verify you're in the right place:**
```bash
ls -la *.tf
```

Should see files like `main.tf`, `variables.tf`, `providers.tf`, etc.

---

### Step 2: Configure Unique Variables (CRITICAL)

**IMPORTANT**: In this workshop, all students share the same AWS account. Each student must set a unique `cluster_name` to avoid conflicts.

Guide them to create a personal tfvars file:

```bash
cat > my-workshop.tfvars << 'EOF'
cluster_name = "eck-<YOUR-NAME>"
project      = "eck-workshop-<YOUR-NAME>"
EOF
```

**Example for student "alice":**
```bash
cat > my-workshop.tfvars << 'EOF'
cluster_name = "eck-alice"
project      = "eck-workshop-alice"
EOF
```

**Verify the file:**
```bash
cat my-workshop.tfvars
```

**Explain:**
```
This file contains YOUR personal settings for the workshop. The most
important one is `cluster_name` - it must be unique because everyone
is deploying to the same AWS account.

Think of it like naming your own workspace. Just like you wouldn't
name a file the same as someone else's, your cluster needs its own
unique name.
```

---

### Step 3: Initialize Terraform

Now run the init command:

```bash
terraform init
```

**Explain what this does:**
```
`terraform init` is always the first command you run in a Terraform project.
It does three important things:

1. **Downloads Providers** - Terraform needs "providers" to talk to cloud
   APIs. We're using the AWS provider, Kubernetes provider, and Helm provider.

2. **Initializes Backend** - Where Terraform stores its "state" - a record
   of what resources exist. For this workshop, we use local state.

3. **Downloads Modules** - Reusable chunks of Terraform code. Our project
   uses modules for VPC, EKS, Elasticsearch, etc.
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 5.0"...
- Finding hashicorp/kubernetes versions matching ">= 2.0"...
- Finding hashicorp/helm versions matching ">= 2.0"...
...
Terraform has been successfully initialized!
```

---

### Step 4: Verify Provider Downloads

```bash
ls -la .terraform/providers/
```

**Explain:**
```
The .terraform directory now contains the downloaded provider plugins.
These are the actual binaries that Terraform uses to create AWS resources,
Kubernetes objects, and Helm releases.

You don't need to understand what's in here - just know that this is
where Terraform keeps its tools.
```

---

### Step 5: Preview the Infrastructure (Terraform Plan)

Before creating anything, let's see what Terraform WILL create:

```bash
terraform plan -var-file="my-workshop.tfvars"
```

**IMPORTANT**: Always use `-var-file` with your personal config!

**Explain:**
```
`terraform plan` is a dry run. It shows you exactly what Terraform
would create, modify, or destroy - without actually doing it.

This is one of the most powerful features of infrastructure as code:
you can review changes before applying them.
```

**Expected output highlights:**
- `Plan: XX to add, 0 to change, 0 to destroy`
- Resources will include: VPC, subnets, EKS cluster, node groups, etc.
- Look for your unique cluster name in the output

**Point out key resources:**
```
Let me highlight a few important things in this plan:

- `module.vpc` - Creates your Virtual Private Cloud with subnets
- `module.eks` - Creates the Kubernetes cluster named "<your-cluster-name>"
- `module.eck_operator` - Installs the Elastic Cloud operator via Helm
- `module.elasticsearch_*` - Creates Elasticsearch clusters
- `module.kibana` - Creates Kibana for visualization
- `module.fleet_server` - Creates Fleet for agent management

That's a lot of infrastructure! Terraform will create all of this
from the code in this directory.
```

---

### Step 6: Understand State Files

**Explain:**
```
After you run `terraform apply`, Terraform creates a file called
`terraform.tfstate`. This is CRUCIAL - it's how Terraform knows what
resources it created.

Never delete this file while resources exist! If you lose it, Terraform
won't know about your cloud resources, and you'd have to manually clean
them up in the AWS console.

For production systems, you'd store this in a remote backend like S3.
For this workshop, local state is fine.
```

---

## Summary of Key Commands

```bash
# Navigate to terraform directory
cd terraform

# Create your personal config (DO THIS FIRST!)
cat > my-workshop.tfvars << 'EOF'
cluster_name = "eck-YOUR-NAME"
project      = "eck-workshop-YOUR-NAME"
EOF

# Initialize terraform
terraform init

# Preview what will be created (always use -var-file!)
terraform plan -var-file="my-workshop.tfvars"
```

---

## Troubleshooting

### "Could not load plugin"

**Cause**: Network issue or corrupted download.

**Fix**:
```bash
rm -rf .terraform
terraform init
```

### "Error acquiring state lock"

**Cause**: Another Terraform process is running, or a previous run crashed.

**Fix** (only if you're sure no other process is running):
```bash
# Check for running terraform processes
ps aux | grep terraform

# If none found, you may need to remove stale lock
# (Be VERY careful with this)
rm -f .terraform.lock.hcl
terraform init
```

### "Invalid provider version"

**Cause**: Terraform version mismatch.

**Fix**:
```bash
terraform --version
# Should be 1.5.0 or higher

# If outdated
brew upgrade terraform
```

### "Cluster name already exists" (during plan)

**Cause**: Someone else used the same name.

**Fix**: Choose a more unique name in your tfvars:
```hcl
cluster_name = "eck-alice-2024"
```

---

## What Success Looks Like

Phase 3 is complete when:
1. ✓ `terraform init` completed without errors
2. ✓ Personal tfvars file created with unique cluster_name
3. ✓ `terraform plan -var-file="my-workshop.tfvars"` shows resources to create
4. ✓ Student understands what will be created

---

## Pre-flight Validation (Before Phase 4)

**IMPORTANT:** Before transitioning to Phase 4, run pre-flight checks!

Load the `preflight-validation` skill and run all checks:

```
Before we deploy infrastructure, let me run a quick pre-flight check
to make sure everything is ready...
```

Run these validations:
1. AWS credentials valid
2. AWS profile set to `eck-workshop`
3. AWS permissions sufficient
4. Terraform initialized
5. tfvars file exists with unique cluster_name
6. Cluster name not already in use
7. Region is us-east-2

**If any checks fail:** Fix them before proceeding!

**If all checks pass:** Show the summary and continue.

---

## Transition to Phase 4

```
Excellent! Terraform is initialized, your config is ready, and all
pre-flight checks passed!

## Pre-flight Summary
✓ AWS credentials valid
✓ Profile: eck-workshop
✓ Permissions: OK
✓ Cluster name: {their-name} (available)
✓ Region: us-east-2
✓ Terraform: initialized

You now understand:
- How Terraform downloads providers to talk to cloud APIs
- How your unique cluster_name keeps your resources separate
- What infrastructure will be created

## Cost Reminder
The infrastructure we're about to deploy costs approximately:
- ~$0.42/hour while running
- ~$10/day if left running

Remember to run /cleanup when you're done!

Next up: Phase 4 - Deploy VPC & EKS

This is where the real action happens! We'll create your Kubernetes
cluster on AWS. The VPC takes about 2 minutes, and EKS takes about
15 minutes. I'll explain the architecture while we wait.

Ready to deploy your infrastructure? (**yes** / **no** / **tell me more**)
```
