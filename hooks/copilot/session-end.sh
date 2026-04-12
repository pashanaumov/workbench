#!/usr/bin/env bash
set -euo pipefail

# Hook: sessionEnd
# Trigger: Fires when a Copilot session completes (complete, error, abort, etc.)
# Adaptation: Map to your tool's session cleanup or shutdown hook
#
# Responsibilities:
# - Write extract-pending flag for final extraction
# - Increment session completion counter
# - Optionally index session note into MemPalace
# - Clean up per-session state files
#
# Note: Because this fires after the session ends, the extraction happens
# at the start of the NEXT session (when the agent reads the flag).

# Get script directory for sourcing helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source detection helpers
if [ -f "$SCRIPT_DIR/lib/detect.sh" ]; then
  source "$SCRIPT_DIR/lib/detect.sh"
fi

# Read JSON input from stdin
INPUT=$(cat)

# Workbench root
WORKBENCH_ROOT="${WORKBENCH_ROOT:-$HOME/.workbench}"

# Read session key
SESSION_KEY_FILE="$WORKBENCH_ROOT/.tmp/current-session"
if [ ! -f "$SESSION_KEY_FILE" ]; then
  # No session key, exit silently
  exit 0
fi

SESSION_KEY=$(cat "$SESSION_KEY_FILE")

# Write extract-pending flag (final extraction for this session)
touch "$WORKBENCH_ROOT/.tmp/extract-pending"

# Increment session count (append + count lines)
SESSION_COUNT_FILE="$WORKBENCH_ROOT/.tmp/session-count"
echo "1" >> "$SESSION_COUNT_FILE"

# Optional: Index session note into MemPalace
if mempalace_enabled 2>/dev/null; then
  SESSION_NOTE="$WORKBENCH_ROOT/session-memory/${SESSION_KEY}.md"
  if [ -f "$SESSION_NOTE" ]; then
    mempalace mine "$SESSION_NOTE" --mode convos >/dev/null 2>&1 || true
  fi
fi

# Clean up per-session counter
COUNTER_FILE="$WORKBENCH_ROOT/.tmp/tool-count-$SESSION_KEY"
if [ -f "$COUNTER_FILE" ]; then
  rm -f "$COUNTER_FILE"
fi

exit 0
