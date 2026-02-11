# /verify - Verify Current Phase is Complete

When the user runs `/verify`, check if they've completed their current phase.

## 1. Read State

Read `.workshop-state.json` to get the current phase.

## 2. Run Verification Based on Phase

### Phase 1: Prerequisites
Run these checks:
```bash
aws --version
terraform --version
kubectl version --client
helm version
```

**Pass if**: All 4 commands return version info (exit code 0)

### Phase 2: AWS Credentials
Run:
```bash
aws sts get-caller-identity
aws configure get region
```

**Pass if**:
- `get-caller-identity` returns account info
- Region is set (preferably us-east-2)

### Phase 3: Terraform Init
Run:
```bash
ls ../terraform/.terraform
terraform -chdir=../terraform providers
```

**Pass if**:
- `.terraform` directory exists
- Providers are listed

### Phase 4: Deploy VPC & EKS
Run:
```bash
kubectl get nodes
```

**Pass if**:
- Nodes are listed
- All nodes show STATUS=Ready

### Phase 5: Deploy ECK Stack
Run:
```bash
kubectl get elasticsearch,kibana,agent -n elastic-system
```

**Pass if**:
- Elasticsearch HEALTH=green
- Kibana HEALTH=green
- Agents show AVAILABLE > 0

### Phase 6: Verify & Explore
Ask the student:
```
Can you confirm:
1. You accessed Kibana at https://localhost:5601 (or via DNS)
2. You logged in successfully
3. You can see logs in the Discover tab

Type 'yes' if all three are true.
```

**Pass if**: Student confirms yes

## 3. Handle Results

### If Passed:
```
## Phase {N} Complete! ✓

Great work! You've successfully completed {phase name}.

{Brief summary of what they accomplished}

Ready for Phase {N+1}: {next phase name}?
```

Update `.workshop-state.json`:
- Increment `currentPhase`
- Add phase to `completedSteps`
- Update `lastActivity`

### If Failed:
```
## Not quite there yet

{Specific item that failed}:
{The actual output or error}

Here's how to fix it:
{Specific guidance}

Try again and run /verify when ready.
```

Do NOT advance the phase.
