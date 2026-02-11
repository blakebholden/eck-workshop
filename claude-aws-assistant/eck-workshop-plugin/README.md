# ECK Workshop Plugin

A Claude Code plugin that transforms Claude into an educational workshop instructor for deploying Elastic Cloud on Kubernetes (ECK) to AWS EKS.

## Features

### Session Start Hook
Automatically injects workshop instructor context when Claude Code starts:
- Warm, educational teaching style
- Verbose command explanations (tool, what, why, expected output)
- Phase tracking instructions
- Safety guidelines

### Safety Check Hook
Intercepts Bash commands and:
- **Blocks** truly dangerous commands (`rm -rf /`, etc.)
- **Warns** on destructive operations (`terraform destroy`, `kubectl delete namespace`)
- Requires explicit confirmation for destructive actions
- Warnings shown once per session

### Slash Commands
- `/workshop` - Start or resume the guided workshop
- `/status` - Check current progress
- `/verify` - Verify current phase is complete
- `/phase <n>` - Jump to a specific phase
- `/troubleshoot` - Diagnose issues
- `/cleanup` - Safe teardown with confirmation

## Installation

### Option 1: Install via Claude Code
```bash
cd /path/to/ECK_Prod
claude plugin install ./claude-aws-assistant/eck-workshop-plugin
```

### Option 2: Manual Configuration
Add to your project's `.claude/settings.json`:
```json
{
  "plugins": ["./claude-aws-assistant/eck-workshop-plugin"]
}
```

## How It Works

### SessionStart Hook
When a new Claude Code session starts, `hooks/session-start.sh` outputs JSON that injects context:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "You are an ECK Workshop Instructor..."
  }
}
```

This makes Claude behave as a patient, educational instructor throughout the session.

### PreToolUse Hook (Bash)
Before any Bash command runs, `hooks/safety-check.py` checks for dangerous patterns:
- Exit 0 = Allow command
- Exit 2 = Block command (with message to stderr)

Warnings are tracked per-session so they only show once.

## Customization

### Modify Teaching Style
Edit `hooks/session-start.sh` to change:
- Tone and personality
- What explanations are required
- How verbose the output should be

### Add/Remove Safety Checks
Edit `hooks/safety-check.py` to:
- Add patterns to `BLOCKED_PATTERNS` (always blocked)
- Add patterns to `WARNING_PATTERNS` (warn then allow)
- Remove patterns you don't need

### Modify Workshop Phases
Edit the `/workshop` command in `commands/workshop.md` to change:
- Phase order or content
- Welcome message
- Phase completion criteria

## File Structure

```
eck-workshop-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── hooks/
│   ├── hooks.json           # Hook definitions
│   ├── session-start.sh     # Injects instructor context
│   └── safety-check.py      # Blocks dangerous commands
├── commands/
│   ├── workshop.md          # /workshop command
│   ├── status.md            # /status command
│   ├── verify.md            # /verify command
│   ├── phase.md             # /phase command
│   ├── troubleshoot.md      # /troubleshoot command
│   └── cleanup.md           # /cleanup command
└── README.md
```

## Requirements

- Claude Code v2.1+
- Python 3.6+ (for safety hook)
- Bash (for session start hook)
