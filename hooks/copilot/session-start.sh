#!/usr/bin/env bash
set -euo pipefail

# Hook: sessionStart
# Trigger: Fires when a new or resumed Copilot session begins
# Adaptation: Map to your tool's session initialization hook
#
# Responsibilities:
# - Derive session key from cwd + timestamp
# - Copy MEMORY.md to active-memory.md (or use MemPalace wake-up if enabled)
# - Check dream gate (time + session count)
# - Reset tool counter

echo "🔧 [Workbench] Session starting..." >&2

# Get script directory for sourcing helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source detection helpers
if [ -f "$SCRIPT_DIR/lib/detect.sh" ]; then
  source "$SCRIPT_DIR/lib/detect.sh"
fi

# Read JSON input from stdin
INPUT=$(cat)

# Parse fields (Copilot passes: cwd, timestamp)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TIMESTAMP=$(echo "$INPUT" | jq -r '.timestamp // empty' 2>/dev/null || echo "")

# Workbench root
WORKBENCH_ROOT="${WORKBENCH_ROOT:-$HOME/.workbench}"

echo "🔧 [Workbench] Loading memory from $WORKBENCH_ROOT" >&2

# Config defaults
MIN_SESSIONS=5
MIN_HOURS=24

# Try to read from config.yaml (fallback to defaults if missing)
if [ -f "$WORKBENCH_ROOT/config.yaml" ]; then
  if command -v yq >/dev/null 2>&1; then
    MIN_SESSIONS=$(yq e '.dream.min_sessions // 5' "$WORKBENCH_ROOT/config.yaml")
    MIN_HOURS=$(yq e '.dream.min_hours // 24' "$WORKBENCH_ROOT/config.yaml")
  else
    # Fallback: grep + awk
    MIN_SESSIONS=$(grep -A1 'dream:' "$WORKBENCH_ROOT/config.yaml" | grep 'min_sessions:' | awk '{print $2}' || echo "5")
    MIN_HOURS=$(grep -A2 'dream:' "$WORKBENCH_ROOT/config.yaml" | grep 'min_hours:' | awk '{print $2}' || echo "24")
  fi
fi

# Derive session key
CWD_SLUG=$(basename "${CWD:-unknown}" | tr -cd '[:alnum:]-')
EPOCH_MINUTES=$(($(date +%s) / 60))
SESSION_KEY="${CWD_SLUG}-${EPOCH_MINUTES}"

# Write session key
mkdir -p "$WORKBENCH_ROOT/.tmp"
echo "$SESSION_KEY" > "$WORKBENCH_ROOT/.tmp/current-session"

# Copy MEMORY.md to active-memory.md (or use MemPalace wake-up if enabled)
ACTIVE_MEMORY="$WORKBENCH_ROOT/.tmp/active-memory.md"

# Try MemPalace wake-up if enabled
if mempalace_enabled 2>/dev/null; then
  if mempalace wake-up > "$ACTIVE_MEMORY" 2>/dev/null; then
    # Success - MemPalace wake-up written
    :
  else
    # Fallback to MEMORY.md copy
    if [ -f "$WORKBENCH_ROOT/memory/MEMORY.md" ]; then
      cp "$WORKBENCH_ROOT/memory/MEMORY.md" "$ACTIVE_MEMORY"
    else
      echo "# Memory" > "$ACTIVE_MEMORY"
      echo "" >> "$ACTIVE_MEMORY"
      echo "_No consolidations yet. Run /dream after a few sessions._" >> "$ACTIVE_MEMORY"
    fi
  fi
else
  # MemPalace disabled or not available - use MEMORY.md
  if [ -f "$WORKBENCH_ROOT/memory/MEMORY.md" ]; then
    cp "$WORKBENCH_ROOT/memory/MEMORY.md" "$ACTIVE_MEMORY"
  else
    echo "# Memory" > "$ACTIVE_MEMORY"
    echo "" >> "$ACTIVE_MEMORY"
    echo "_No consolidations yet. Run /dream after a few sessions._" >> "$ACTIVE_MEMORY"
  fi
fi

# Reset tool counter
echo "0" > "$WORKBENCH_ROOT/.tmp/tool-count-$SESSION_KEY"

# Dream gate check
DREAM_LOCK="$WORKBENCH_ROOT/.tmp/dream-lock"
SESSION_COUNT_FILE="$WORKBENCH_ROOT/.tmp/session-count"

# Get session count
if [ -f "$SESSION_COUNT_FILE" ]; then
  SESSION_COUNT=$(wc -l < "$SESSION_COUNT_FILE" | tr -d ' ')
else
  SESSION_COUNT=0
fi

# Get time since last dream (portable: try macOS stat, then Linux stat)
if [ -f "$DREAM_LOCK" ]; then
  if LAST_DREAM=$(stat -f %m "$DREAM_LOCK" 2>/dev/null); then
    : # macOS
  elif LAST_DREAM=$(stat -c %Y "$DREAM_LOCK" 2>/dev/null); then
    : # Linux
  else
    LAST_DREAM=0
  fi
else
  LAST_DREAM=0
fi

NOW=$(date +%s)
HOURS_SINCE_DREAM=$(( (NOW - LAST_DREAM) / 3600 ))

# Check both gates
if [ "$SESSION_COUNT" -ge "$MIN_SESSIONS" ] && [ "$HOURS_SINCE_DREAM" -ge "$MIN_HOURS" ]; then
  touch "$WORKBENCH_ROOT/.tmp/dream-pending"
  echo "🔧 [Workbench] Dream consolidation pending (${SESSION_COUNT} sessions, ${HOURS_SINCE_DREAM}h)" >&2
fi

echo "✅ [Workbench] Session started successfully" >&2
exit 0
