# ECK Workshop Assistant

A Claude Code plugin that guides students through deploying Elastic Cloud on Kubernetes (ECK) to AWS EKS.

## For Workshop Instructors

### Before the Workshop

1. **Ensure AWS Bedrock access** is enabled in your AWS account
   - Claude Code uses AWS Bedrock (no separate API key needed)
   - Students use their existing AWS credentials

2. **Test the workshop** yourself to verify everything works

3. **Prepare student access**:
   - Each student needs AWS credentials for your shared account
   - Each student needs a unique cluster name (e.g., `eck-studentname-dev`)

### During the Workshop

1. Students should already have AWS credentials configured via `/root/.workshop-env`

2. Students run the installer:
   ```bash
   ./claude-aws-assistant/install.sh
   ```

3. Start Claude Code and begin:
   ```bash
   claude
   ```
   Then type `/workshop`

### After the Workshop

1. Have students run `/cleanup` to destroy AWS resources
2. Verify all student clusters are destroyed to avoid charges
3. Collect feedback!

## For Students

### Quick Start

```bash
# Ensure AWS credentials are set
source /root/.workshop-env

# Run setup
./claude-aws-assistant/install.sh

# Start the workshop
claude
```

Once in Claude, type `/workshop` to begin.

### Workshop Commands

| Command | Description |
|---------|-------------|
| `/workshop` | Start or resume the workshop |
| `/status` | Check your progress |
| `/verify` | Verify current phase is complete |
| `/troubleshoot` | Get help with issues |
| `/cleanup` | Tear down resources when done |

### The 8 Phases

| Phase | Challenge | Goal |
|-------|-----------|------|
| 1 | Environment Setup | Configure AWS credentials |
| 2 | Deploy Infrastructure | Deploy VPC + EKS cluster |
| 3 | Deploy ECK Stack | Deploy ES, Kibana, Gateway |
| 4 | Fleet & Monitoring | Deploy Fleet Server + Agents |
| 5 | APM & Observability | Deploy APM + OTel Demo |
| 6 | ML & ELSER | Add ML nodes, deploy ELSER |
| 7 | AI Assistant | Configure LLM connector |
| 8 | Exploration | Free exploration |

### Accessing Kibana

#### Via Jump Box (Recommended)
1. Get jumpbox IP: `terraform output jumpbox_public_ip`
2. Get password: Run command from `terraform output jumpbox_password_command`
3. RDP to jumpbox, open browser
4. Navigate to: `https://kibana.elastic.internal`

#### Via Port Forward
```bash
kubectl port-forward svc/kibana-kb-http -n elastic-system 5601:5601
# Access https://localhost:5601
```

### Troubleshooting

If you get stuck:
1. Try `/troubleshoot` for automated diagnosis
2. Run `source /root/.workshop-env` to refresh credentials
3. Ask your instructor

## File Structure

```
claude-aws-assistant/
├── .claude-plugin/
│   └── plugin.json         # Plugin manifest
├── commands/
│   ├── workshop.md         # /workshop command
│   ├── status.md           # /status command
│   ├── verify.md           # /verify command
│   ├── troubleshoot.md     # /troubleshoot command
│   └── cleanup.md          # /cleanup command
├── hooks/
│   └── safety-check.sh     # Blocks dangerous commands
├── CLAUDE.md               # Main workshop instructions
├── install.sh              # Student setup script
└── README.md               # This file
```

## Authentication

This workshop uses **AWS Bedrock** for Claude Code authentication:
- No separate API key required
- Uses the same AWS credentials students already have
- Requires `CLAUDE_CODE_USE_BEDROCK=1` environment variable
- Requires `AWS_REGION` to be set (default: us-east-2)

## Customization

### Modify the Phases

Edit `CLAUDE.md` to change:
- Phase order or content
- Teaching style
- Troubleshooting guidance

### Add New Commands

Create a new `.md` file in `commands/` and add it to `.claude-plugin/plugin.json`.

### Change Safety Rules

Edit `hooks/safety-check.sh` to add/remove blocked patterns.
