#!/usr/bin/env bash
set -euo pipefail

# Hook: postToolUse
# Trigger: Fires after every tool execution in Copilot
# Adaptation: Map to your tool's post-action or post-command hook
#
# Responsibilities:
# - Increment per-session tool call counter
# - When threshold reached, write extract-pending flag
# - Reset counter after triggering

# Read JSON input from stdin
INPUT=$(cat)

# Workbench root
WORKBENCH_ROOT="${WORKBENCH_ROOT:-$HOME/.workbench}"

# Config default
MIN_TOOL_CALLS=3

# Try to read from config.yaml
if [ -f "$WORKBENCH_ROOT/config.yaml" ]; then
  if command -v yq >/dev/null 2>&1; then
    MIN_TOOL_CALLS=$(yq e '.session_extract.min_tool_calls // 3' "$WORKBENCH_ROOT/config.yaml")
  else
    MIN_TOOL_CALLS=$(grep -A1 'session_extract:' "$WORKBENCH_ROOT/config.yaml" | grep 'min_tool_calls:' | awk '{print $2}' || echo "3")
  fi
fi

# Read session key
SESSION_KEY_FILE="$WORKBENCH_ROOT/.tmp/current-session"
if [ ! -f "$SESSION_KEY_FILE" ]; then
  # Session started before hooks were installed, exit silently
  exit 0
fi

SESSION_KEY=$(cat "$SESSION_KEY_FILE")
COUNTER_FILE="$WORKBENCH_ROOT/.tmp/tool-count-$SESSION_KEY"

# Increment counter (append + count lines)
echo "1" >> "$COUNTER_FILE"
COUNT=$(wc -l < "$COUNTER_FILE" | tr -d ' ')

# Check threshold
if [ "$COUNT" -ge "$MIN_TOOL_CALLS" ]; then
  touch "$WORKBENCH_ROOT/.tmp/extract-pending"
  # Reset counter
  echo "0" > "$COUNTER_FILE"
fi

exit 0
