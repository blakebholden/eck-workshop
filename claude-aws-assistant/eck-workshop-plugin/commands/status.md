# /status - Check Workshop Progress

When the user runs `/status`, show them where they are in the workshop.

## 1. Read State

Read `.workshop-state.json`. If it doesn't exist, tell them to run `/workshop` first.

## 2. Display Progress

Show a visual progress indicator:

```
# Workshop Progress

Phase 1: Prerequisites     [✓] Complete
Phase 2: AWS Credentials   [✓] Complete
Phase 3: Terraform Init    [→] In Progress
Phase 4: Deploy VPC & EKS  [ ] Not started
Phase 5: Deploy ECK Stack  [ ] Not started
Phase 6: Verify & Explore  [ ] Not started

Current: Phase 3 - Terraform Init
Started: {startedAt}
Last activity: {lastActivity}
```

Use:
- `[✓]` for completed phases
- `[→]` for current phase
- `[ ]` for not started

## 3. Show Next Step

After the progress display, remind them what's next:

```
## Next Step

{Description of what they should do next in the current phase}

Run /verify to check if this phase is complete, or just ask me for help!
```

## 4. Offer Options

```
What would you like to do?
- Continue with the current phase
- /verify to check completion
- /troubleshoot if you're stuck
```
