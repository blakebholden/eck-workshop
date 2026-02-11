#!/bin/bash
# Safety hook - runs before tool execution
# Intercepts dangerous commands and blocks them unless confirmed

# This hook receives the tool name and arguments
# It should exit 0 to allow, exit 1 to block

TOOL_NAME="$1"
COMMAND="$2"

# Only check Bash commands
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

# Patterns that require confirmation
DANGEROUS_PATTERNS=(
    "terraform destroy"
    "terraform apply -destroy"
    "kubectl delete namespace"
    "kubectl delete -A"
    "kubectl delete all"
    "aws eks delete-cluster"
    "aws ec2 terminate-instances"
    "rm -rf"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qi "$pattern"; then
        echo "BLOCKED: Dangerous command detected: $pattern"
        echo ""
        echo "This command will delete resources. Use /cleanup for safe teardown,"
        echo "or explicitly confirm this action in your message."
        exit 1
    fi
done

# Allow the command
exit 0
