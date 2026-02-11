# Skill: AWS Credentials & CLI Profile Setup

Load this skill when helping students configure AWS credentials in Phase 2.

## Overview

Students need working AWS credentials with sufficient permissions to create VPCs, EKS clusters, and related resources. This workshop uses a named profile called `eck-workshop`.

---

## Step-by-Step Guide

### Step 1: Check if AWS CLI is Configured

First, check if they have any existing credentials:

```bash
aws sts get-caller-identity
```

**If it works**: They have default credentials. Ask if they want to use these or create a dedicated profile.

**If it fails with "Unable to locate credentials"**: They need to configure credentials. Continue to Step 2.

**If it fails with "ExpiredToken"**: Their session/token expired. They need to re-authenticate or refresh.

---

### Step 2: Gather Credentials

Before configuring, the student needs:

1. **AWS Access Key ID** - Starts with `AKIA...`
2. **AWS Secret Access Key** - The secret part (only shown once when created)

**If they don't have these**, guide them:

```
To get AWS credentials:

1. Log into the AWS Console: https://console.aws.amazon.com
2. Click your username (top right) → "Security credentials"
3. Scroll to "Access keys" section
4. Click "Create access key"
5. Choose "Command Line Interface (CLI)"
6. Check the confirmation box and click Next
7. Download the .csv file (IMPORTANT - you can't see the secret again!)

Have your Access Key ID and Secret Access Key ready.
```

**For workshop accounts**: The instructor may provide credentials directly. Students should have received these via email or handout.

---

### Step 3: Configure the Named Profile

We use a named profile (`eck-workshop`) to avoid conflicts with existing AWS configs:

```bash
aws configure --profile eck-workshop
```

This prompts for:

| Prompt | What to Enter |
|--------|---------------|
| AWS Access Key ID | Their access key (AKIA...) |
| AWS Secret Access Key | Their secret key |
| Default region name | `us-east-2` (recommended for this workshop) |
| Default output format | `json` (or just press Enter) |

**Walk them through each prompt one at a time.**

---

### Step 4: Set the Profile as Active

After configuring, they need to tell the CLI to USE this profile:

**Option A: Environment variable (recommended for workshop)**
```bash
export AWS_PROFILE=eck-workshop
```

This lasts for the current terminal session. They'll need to run it again if they open a new terminal.

**Option B: Add to shell profile (persists across sessions)**
```bash
echo 'export AWS_PROFILE=eck-workshop' >> ~/.zshrc
source ~/.zshrc
```

Or for bash:
```bash
echo 'export AWS_PROFILE=eck-workshop' >> ~/.bashrc
source ~/.bashrc
```

---

### Step 5: Verify It Works

Run the identity check:

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAEXAMPLEID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/workshop-user"
}
```

**Check the region:**
```bash
aws configure get region --profile eck-workshop
```

Should return: `us-east-2`

---

### Step 6: Verify Permissions

The credentials need permissions for VPC, EKS, EC2, and IAM. Quick test:

```bash
# Test EC2 access
aws ec2 describe-vpcs --max-results 1

# Test EKS access
aws eks list-clusters
```

If these work without "AccessDenied" errors, they're good to go.

---

## Troubleshooting Common Issues

### "Unable to locate credentials"

**Cause**: No credentials configured, or profile not set.

**Fix**:
```bash
# Check if profile exists
aws configure list --profile eck-workshop

# If empty, run configure again
aws configure --profile eck-workshop

# Make sure profile is active
export AWS_PROFILE=eck-workshop
```

---

### "The security token included in the request is expired"

**Cause**: Using temporary credentials (STS) that have expired.

**Fix**:
- If using SSO: `aws sso login --profile eck-workshop`
- If using session tokens: Get new credentials from your admin
- If using IAM user keys: These don't expire - check if the key was deactivated

---

### "InvalidClientTokenId" or "SignatureDoesNotMatch"

**Cause**: The access key or secret key is wrong.

**Fix**:
```bash
# Re-enter credentials
aws configure --profile eck-workshop
```

Double-check for:
- Copy/paste errors (extra spaces)
- Wrong key pair (maybe from a different account)
- Deactivated access key

---

### "Access Denied" on specific operations

**Cause**: The IAM user/role doesn't have required permissions.

**Required permissions for this workshop**:
- `ec2:*` (VPC, subnets, security groups)
- `eks:*` (EKS cluster management)
- `iam:*` (creating roles for EKS)
- `elasticloadbalancing:*` (for load balancers)

**Fix**: Contact your AWS administrator or workshop instructor to get the right permissions attached to your IAM user/role.

---

### Profile works in one terminal but not another

**Cause**: `AWS_PROFILE` environment variable not set in the new terminal.

**Fix**:
```bash
# Run in each new terminal
export AWS_PROFILE=eck-workshop

# Or add to shell profile for persistence
echo 'export AWS_PROFILE=eck-workshop' >> ~/.zshrc
```

---

### Using AWS SSO (Single Sign-On)

If the organization uses AWS SSO instead of IAM users:

```bash
# Configure SSO
aws configure sso --profile eck-workshop

# Login
aws sso login --profile eck-workshop

# Set the profile
export AWS_PROFILE=eck-workshop

# Verify
aws sts get-caller-identity
```

SSO sessions expire (typically 8-12 hours). If you get expired token errors, run `aws sso login --profile eck-workshop` again.

---

### Multiple AWS Accounts

If the student has multiple AWS configurations:

```bash
# List all profiles
aws configure list-profiles

# See which profile is active
echo $AWS_PROFILE

# Switch profiles
export AWS_PROFILE=eck-workshop
```

---

## Quick Reference Commands

```bash
# Configure new profile
aws configure --profile eck-workshop

# Set active profile
export AWS_PROFILE=eck-workshop

# Check current identity
aws sts get-caller-identity

# Check current region
aws configure get region

# List all profiles
aws configure list-profiles

# See full config for a profile
aws configure list --profile eck-workshop
```

---

## What Success Looks Like

When Phase 2 is complete, the student should be able to run:

```bash
aws sts get-caller-identity
```

And see valid output with their account ID, without any errors.

They should also confirm:
- Region is set to `us-east-2`
- `AWS_PROFILE=eck-workshop` is active (or they're using default creds intentionally)
