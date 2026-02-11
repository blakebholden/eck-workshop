# /cleanup - Tear Down Workshop Resources

When the user runs `/cleanup`, help them safely destroy all resources.

## 1. Confirm Intent

This is a destructive operation. Always confirm:

```
## Workshop Cleanup

This will PERMANENTLY DELETE all AWS resources created during the workshop:
- EKS cluster and all workloads
- VPC, subnets, NAT gateways
- All Elasticsearch data
- Load balancers, security groups, etc.

Estimated AWS charges stop after cleanup completes.

⚠️  This cannot be undone.

Type 'destroy' to confirm, or 'cancel' to abort:
```

**WAIT for the user to type 'destroy'**. Do not proceed on anything else.

## 2. If Cancelled

```
Cleanup cancelled. Your resources are still running.

Remember: AWS charges apply while resources exist.
Run /cleanup again when you're ready to tear down.
```

## 3. If Confirmed

### Step 1: Check Current State

```
Starting cleanup...

First, let me check what's deployed...
```

Run:
```bash
cd ../terraform && terraform state list | head -20
```

### Step 2: Destroy in Order

For cleanest deletion, destroy in reverse order:

```
Destroying resources... This takes 10-15 minutes.
```

Run:
```bash
cd ../terraform && terraform destroy -auto-approve
```

### Step 3: Verify Cleanup

After terraform completes:

```bash
# Verify no EKS cluster
aws eks list-clusters --output text

# Verify no VPC (check for the specific one)
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*eck*" --output text
```

### Step 4: Clean Up Local State

```
AWS resources destroyed.

Cleaning up local files...
```

Optionally remove:
- `.workshop-state.json` (ask first)
- `../terraform/.terraform` directory
- `../terraform/terraform.tfstate*`

Ask:
```
Do you want me to also reset your local workshop state?
This will let you start fresh if you run the workshop again.

(yes/no)
```

## 4. Final Message

```
## Cleanup Complete

All AWS resources have been destroyed.
Your AWS charges for this workshop will stop accruing.

Local files:
- Terraform state: {deleted/kept}
- Workshop progress: {reset/kept}

Thanks for participating in the workshop!

If you want to run it again, just run /workshop to start fresh.
```

## 5. Handle Errors

If terraform destroy fails:

```
Cleanup encountered an error:

{error message}

Common fixes:
1. Some resources have dependencies - try running destroy again
2. Resources created outside Terraform need manual deletion
3. Check AWS Console for stuck resources

Want me to try the destroy again?
```
