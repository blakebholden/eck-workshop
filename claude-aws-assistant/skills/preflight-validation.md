# Skill: Pre-flight Validation

Load this skill before Phase 4 (Deploy) to verify everything is ready for deployment.

## When to Use

Run this validation:
- At the end of Phase 3 (after terraform init)
- Before running any `terraform apply` for infrastructure
- If a student has been away and is resuming

## Pre-flight Checklist

### 1. AWS Credentials Validation

```bash
# Check credentials are configured
aws sts get-caller-identity
```

**Expected:** Valid JSON with Account, UserId, Arn

**Check profile is set:**
```bash
echo $AWS_PROFILE
```

**Expected:** `eck-workshop`

**If missing:**
```
⚠️ AWS Profile Not Set

Run this to set your profile:
  export AWS_PROFILE=eck-workshop

Then verify:
  aws sts get-caller-identity
```

---

### 2. AWS Permissions Check

Test key permissions needed for deployment:

```bash
# Test EC2 permissions (VPC creation)
aws ec2 describe-vpcs --max-results 1 --query "Vpcs[0].VpcId" 2>&1

# Test EKS permissions
aws eks list-clusters --max-results 1 2>&1

# Test IAM permissions (needed for EKS roles)
aws iam list-roles --max-items 1 --query "Roles[0].RoleName" 2>&1
```

**If any return "AccessDenied":**
```
⚠️ Insufficient Permissions

Your AWS user is missing required permissions.

Required for this workshop:
- EC2: CreateVpc, CreateSubnet, CreateSecurityGroup, etc.
- EKS: CreateCluster, CreateNodegroup, etc.
- IAM: CreateRole, AttachRolePolicy, etc.
- ELB: CreateLoadBalancer, etc.

Contact your workshop instructor or AWS admin to get:
- AdministratorAccess policy, OR
- Custom policy with EC2, EKS, IAM, ELB full access
```

---

### 3. Tool Version Validation

```bash
# Check AWS CLI version (need v2)
aws --version

# Check Terraform version (need 1.5+)
terraform --version

# Check kubectl
kubectl version --client

# Check Helm
helm version --short
```

**Minimum versions:**
| Tool | Minimum | Check |
|------|---------|-------|
| AWS CLI | 2.0.0 | `aws --version` should show `aws-cli/2.x.x` |
| Terraform | 1.5.0 | `terraform --version` should show `Terraform v1.5+` |
| kubectl | 1.28.0 | `kubectl version --client` should show `v1.28+` |
| Helm | 3.12.0 | `helm version` should show `v3.12+` |

---

### 4. Terraform State Check

```bash
# Check terraform is initialized
ls terraform/.terraform/providers 2>/dev/null && echo "✓ Initialized" || echo "✗ Not initialized"

# Check tfvars file exists
ls terraform/my-workshop.tfvars 2>/dev/null && echo "✓ Config exists" || echo "✗ Missing config"

# Check cluster name is set
grep "cluster_name" terraform/my-workshop.tfvars 2>/dev/null
```

**If not initialized:**
```
⚠️ Terraform Not Initialized

Run these commands:
  cd terraform
  terraform init
```

**If tfvars missing:**
```
⚠️ Personal Config Missing

Create your config file:
  cd terraform
  cat > my-workshop.tfvars << 'EOF'
  cluster_name = "eck-YOUR-NAME"
  project      = "eck-workshop-YOUR-NAME"
  EOF
```

---

### 5. Cluster Name Conflict Check

```bash
# Get the cluster name from tfvars
CLUSTER_NAME=$(grep "cluster_name" terraform/my-workshop.tfvars | cut -d'"' -f2)

# Check if cluster already exists
aws eks describe-cluster --name "${CLUSTER_NAME}-dev" --region us-east-2 2>&1
```

**If cluster exists:**
```
⚠️ Cluster Name Conflict!

A cluster named "{cluster_name}-dev" already exists in this AWS account.
This could be:
1. Your own cluster from a previous run
2. Another student using the same name

Options:
1. If it's yours and you want to continue: Just proceed with terraform apply
2. If it's not yours: Choose a different cluster name in my-workshop.tfvars

Check who owns it:
  aws eks describe-cluster --name {cluster_name}-dev --query "cluster.tags"
```

**If "ResourceNotFoundException" (cluster doesn't exist):**
```
✓ Cluster name available: {cluster_name}-dev
```

---

### 6. Region Verification

```bash
# Check configured region
aws configure get region

# Check region from environment
echo $AWS_DEFAULT_REGION
```

**Expected:** `us-east-2`

**If different region:**
```
⚠️ Region Mismatch

The workshop is designed for us-east-2.
Your AWS CLI is configured for: {actual_region}

To fix:
  aws configure set region us-east-2 --profile eck-workshop

Or if using environment variable:
  export AWS_DEFAULT_REGION=us-east-2
```

---

### 7. Network Connectivity Check

```bash
# Can we reach AWS APIs?
curl -s --max-time 5 https://sts.us-east-2.amazonaws.com > /dev/null && echo "✓ AWS API reachable" || echo "✗ Cannot reach AWS"

# Can we reach container registries? (needed for pulling images)
curl -s --max-time 5 https://public.ecr.aws > /dev/null && echo "✓ ECR reachable" || echo "✗ Cannot reach ECR"
```

**If connectivity issues:**
```
⚠️ Network Issues

Cannot reach AWS APIs. Check:
1. Internet connection
2. Proxy settings (HTTP_PROXY, HTTPS_PROXY)
3. Firewall rules
4. VPN if required for your network
```

---

## Pre-flight Summary

Display a summary of all checks:

```
## Pre-flight Validation Summary

┌──────────────────────────────────────────────────────────────┐
│ Check                          │ Status                      │
├──────────────────────────────────────────────────────────────┤
│ AWS Credentials                │ ✓ Valid (account: 12345)    │
│ AWS Profile                    │ ✓ eck-workshop              │
│ AWS Permissions                │ ✓ Sufficient                │
│ AWS Region                     │ ✓ us-east-2                 │
│ Terraform Initialized          │ ✓ Yes                       │
│ Personal Config (tfvars)       │ ✓ Found                     │
│ Cluster Name                   │ ✓ eck-alice (available)     │
│ Tool Versions                  │ ✓ All minimum met           │
│ Network Connectivity           │ ✓ AWS APIs reachable        │
└──────────────────────────────────────────────────────────────┘

✅ All checks passed! Ready to deploy.
```

Or if issues found:

```
## Pre-flight Validation Summary

┌──────────────────────────────────────────────────────────────┐
│ Check                          │ Status                      │
├──────────────────────────────────────────────────────────────┤
│ AWS Credentials                │ ✓ Valid                     │
│ AWS Profile                    │ ⚠️ Not set                  │
│ AWS Permissions                │ ✓ Sufficient                │
│ AWS Region                     │ ✓ us-east-2                 │
│ Terraform Initialized          │ ✓ Yes                       │
│ Personal Config (tfvars)       │ ✓ Found                     │
│ Cluster Name                   │ ❌ Already exists!          │
│ Tool Versions                  │ ✓ All minimum met           │
│ Network Connectivity           │ ✓ AWS APIs reachable        │
└──────────────────────────────────────────────────────────────┘

⚠️ Issues found! Please fix before deploying:

1. Set AWS profile:
   export AWS_PROFILE=eck-workshop

2. Choose a different cluster name:
   Edit terraform/my-workshop.tfvars
   Change cluster_name to something unique

Would you like help fixing these issues? (**yes** / **no**)
```

---

## Integration with Workshop Flow

At the end of Phase 3 (Terraform Init), ALWAYS run pre-flight validation before transitioning to Phase 4:

```
## Phase 3 Complete!

Before we deploy infrastructure, let me run a quick pre-flight check
to make sure everything is ready...

[Run pre-flight validation]

{If all passed}
All systems go! Ready to deploy your infrastructure.

{If issues found}
We need to fix a few things before deploying...
[Show issues and fixes]
```
