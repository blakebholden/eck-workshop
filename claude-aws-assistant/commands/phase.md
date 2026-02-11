# /phase - Jump to a Specific Phase

When the user runs `/phase <number>`, attempt to jump to that phase.

## Usage

- `/phase 1` - Go to Prerequisites
- `/phase 2` - Go to AWS Credentials
- `/phase 3` - Go to Terraform Init
- `/phase 4` - Go to Deploy VPC & EKS
- `/phase 5` - Go to Deploy ECK Stack
- `/phase 6` - Go to Verify & Explore

## 1. Parse the Argument

Extract the phase number from the command. If no number given, show usage:

```
Usage: /phase <number>

Phases:
1. Prerequisites
2. AWS Credentials
3. Terraform Init
4. Deploy VPC & EKS
5. Deploy ECK Stack
6. Verify & Explore

Example: /phase 3
```

## 2. Validate the Request

### Going Backward (to an earlier phase)
Always allow this. Update state and begin that phase:

```
Jumping back to Phase {N}: {phase name}

Note: Your previous progress is saved. You can /phase forward again anytime.
```

### Going Forward (to a later phase)
Check if prerequisites are met:

- **Phase 2** requires: Phase 1 complete (tools installed)
- **Phase 3** requires: Phase 2 complete (AWS credentials working)
- **Phase 4** requires: Phase 3 complete (terraform initialized)
- **Phase 5** requires: Phase 4 complete (EKS cluster running)
- **Phase 6** requires: Phase 5 complete (ECK stack deployed)

### If Prerequisites NOT Met

```
Can't jump to Phase {N} yet.

You need to complete Phase {N-1} first because:
- {Reason - e.g., "Terraform needs AWS credentials to deploy resources"}

Current phase: {current}

Options:
1. Complete the current phase first
2. Run /verify to check if you're actually ready
```

### If Prerequisites ARE Met (or skipping with override)

```
Jumping to Phase {N}: {phase name}

{Brief description of this phase's goal}

Let's begin...
```

Then start guiding them through that phase.

## 3. Update State

When jumping to a new phase, update `.workshop-state.json`:
```json
{
  "currentPhase": <new phase number>,
  "lastActivity": "<current timestamp>"
}
```

## 4. Special Case: Expert Mode

If the user says something like "I know what I'm doing, skip to phase 5":

```
I can let you skip ahead, but I want to make sure your environment is ready.

Let me quickly verify the prerequisites...
```

Then run the verification checks for all previous phases. If they pass, allow the skip. If they fail, explain what's missing.
