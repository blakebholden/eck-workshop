#!/usr/bin/env python3
"""
ECK Workshop Safety Hook
Blocks dangerous commands and requires confirmation for destructive operations.
"""

import json
import os
import re
import sys

# Patterns that are BLOCKED entirely (exit code 2)
BLOCKED_PATTERNS = [
    (r"rm\s+-rf\s+/", "Cannot run 'rm -rf /' - this would delete your entire system!"),
    (r"rm\s+-rf\s+~", "Cannot run 'rm -rf ~' - this would delete your home directory!"),
    (r"rm\s+-rf\s+\*", "Cannot run 'rm -rf *' - this is too destructive."),
]

# Patterns that require confirmation (show warning, but allow)
WARNING_PATTERNS = [
    (
        r"terraform\s+destroy",
        """⚠️  DESTRUCTIVE OPERATION: terraform destroy

This will PERMANENTLY DELETE all AWS resources:
- EKS cluster and all workloads
- VPC, subnets, NAT gateways
- All Elasticsearch data
- Load balancers, security groups

This cannot be undone. Use /cleanup for guided teardown instead.

If you really need to run this, please confirm explicitly."""
    ),
    (
        r"terraform\s+apply\s+-destroy",
        """⚠️  DESTRUCTIVE OPERATION: terraform apply -destroy

This is equivalent to 'terraform destroy' and will delete all resources.
Use /cleanup for guided teardown instead."""
    ),
    (
        r"kubectl\s+delete\s+namespace",
        """⚠️  WARNING: Deleting a namespace

This will delete ALL resources in the namespace including:
- Deployments, pods, services
- ConfigMaps, secrets
- Persistent volume claims

Make sure you want to delete everything in this namespace."""
    ),
    (
        r"kubectl\s+delete\s+-A",
        """⚠️  WARNING: Deleting across all namespaces

This affects resources in ALL namespaces. This is usually not what you want.
Be very careful with cluster-wide delete operations."""
    ),
    (
        r"aws\s+eks\s+delete-cluster",
        """⚠️  DESTRUCTIVE OPERATION: Deleting EKS cluster

This will delete the entire Kubernetes cluster.
Use /cleanup for proper teardown that handles dependencies."""
    ),
    (
        r"aws\s+ec2\s+terminate-instances",
        """⚠️  WARNING: Terminating EC2 instances

This will immediately terminate the specified instances.
Make sure these aren't part of your EKS cluster."""
    ),
]

# State file to track warnings shown per session
def get_state_file(session_id):
    return os.path.expanduser(f"~/.claude/eck_workshop_warnings_{session_id}.json")

def load_shown_warnings(session_id):
    state_file = get_state_file(session_id)
    if os.path.exists(state_file):
        try:
            with open(state_file, "r") as f:
                return set(json.load(f))
        except (json.JSONDecodeError, IOError):
            return set()
    return set()

def save_shown_warnings(session_id, warnings):
    state_file = get_state_file(session_id)
    try:
        os.makedirs(os.path.dirname(state_file), exist_ok=True)
        with open(state_file, "w") as f:
            json.dump(list(warnings), f)
    except IOError:
        pass

def main():
    # Read input from stdin
    try:
        raw_input = sys.stdin.read()
        input_data = json.loads(raw_input)
    except json.JSONDecodeError:
        sys.exit(0)  # Allow if can't parse

    session_id = input_data.get("session_id", "default")
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Only check Bash commands
    if tool_name != "Bash":
        sys.exit(0)

    command = tool_input.get("command", "")
    if not command:
        sys.exit(0)

    # Check for blocked patterns (always block)
    for pattern, message in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            print(f"🚫 BLOCKED: {message}", file=sys.stderr)
            sys.exit(2)  # Block execution

    # Check for warning patterns (warn once per session, then allow)
    shown_warnings = load_shown_warnings(session_id)

    for pattern, message in WARNING_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            warning_key = pattern

            if warning_key not in shown_warnings:
                shown_warnings.add(warning_key)
                save_shown_warnings(session_id, shown_warnings)

                # Print warning and block first time
                print(message, file=sys.stderr)
                print("\n(This warning is shown once per session. Run the command again to proceed.)", file=sys.stderr)
                sys.exit(2)  # Block first attempt

            # Second attempt - allow through
            break

    # Allow command to proceed
    sys.exit(0)

if __name__ == "__main__":
    main()
