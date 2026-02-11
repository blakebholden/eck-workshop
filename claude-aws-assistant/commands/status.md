# /status - Check Workshop Progress

When the user runs `/status`, show them where they are in the workshop.

## 1. Read State

Read `.workshop-state.json`. If it doesn't exist, tell them to run `/workshop` first.

## 2. Display Progress

Show a visual progress indicator:

```
# Workshop Progress

Phase 1: Environment Setup      [X] Complete
Phase 2: Deploy Infrastructure  [X] Complete
Phase 3: Deploy ECK Stack       [>] In Progress
Phase 4: Fleet & Monitoring     [ ] Not started
Phase 5: APM & Observability    [ ] Not started
Phase 6: ML & ELSER             [ ] Not started
Phase 7: AI Assistant           [ ] Not started
Phase 8: Exploration            [ ] Not started

Current: Phase 3 - Deploy ECK Stack
Cluster: {clusterName}
Started: {startedAt}
Last activity: {lastActivity}
```

Use:
- `[X]` for completed phases
- `[>]` for current phase
- `[ ]` for not started

## 3. Show Next Step

After the progress display, remind them what's next:

```
## Next Step

{Description of what they should do next in the current phase}

Run /verify to check if this phase is complete, or just ask me for help!
```

## 4. Phase Descriptions

| Phase | Description |
|-------|-------------|
| 1 | Environment Setup - Configure AWS credentials and verify tools |
| 2 | Deploy Infrastructure - Create VPC and EKS cluster |
| 3 | Deploy ECK Stack - Deploy Elasticsearch, Kibana, and Gateway |
| 4 | Fleet & Monitoring - Deploy Fleet Server and Elastic Agents |
| 5 | APM & Observability - Deploy APM Server and OTel Demo |
| 6 | ML & ELSER - Add ML node group and deploy ELSER model |
| 7 | AI Assistant - Configure LLM connector for AI features |
| 8 | Exploration - Free exploration and experimentation |

## 5. Offer Options

```
What would you like to do?
- Continue with the current phase
- /verify to check completion
- /troubleshoot if you're stuck
```
