# Copilot Hooks — Reference Implementation

This folder contains a reference implementation of the workbench hook pattern for GitHub Copilot. The pattern is universal — you can adapt it for any tool that supports lifecycle hooks.

In this guide, `<workbenchRoot>` means:
1. `WORKBENCH_ROOT` (if set)
2. `.workbench` in the current project (or nearest parent)
3. `~/.workbench` fallback

## What These Hooks Do

**`session-start.sh`** — Fires when a session begins
- Derives a session key from cwd + timestamp
- Copies `MEMORY.md` to `.tmp/active-memory.md` for the agent to read
- Checks if it's time to run `/dream` (session count + time gate)
- Resets the tool call counter

**`post-tool-use.sh`** — Fires after every tool execution
- Increments a per-session tool call counter
- When counter hits threshold (default: 3), writes `.tmp/extract-pending` flag
- The steering doc tells the agent to check this flag and run `/session-extract`

**`session-end.sh`** — Fires when a session completes
- Writes `.tmp/extract-pending` for final extraction
- Increments the session completion counter
- Cleans up per-session state files

## Installation (Copilot)

1. Copy this folder to your repo:
```bash
mkdir -p .github/hooks
cp -r <workbenchRoot>/hooks/copilot .github/hooks/
chmod +x .github/hooks/copilot/*.sh
```

2. Commit to your default branch (Copilot only reads hooks from default branch)

3. Add the steering doc instructions to `.github/copilot-instructions.md` (see `templates/steering-doc-template.md`)

## The Flag-File Pattern

Hooks can't inject prompts directly into the agent. Instead:

1. Hook writes a flag file (e.g. `.tmp/extract-pending`)
2. Steering doc tells agent: "At each turn, check for this flag"
3. Agent sees flag → runs skill → deletes flag

This pattern works across any tool with hooks + steering docs.

## Adapting for Another Tool

### Step 1: Map the triggers

Find your tool's equivalent lifecycle hooks:

| Copilot Hook | Cursor | Windsurf | Your Tool |
|---|---|---|---|
| `sessionStart` | ? | ? | ? |
| `postToolUse` | ? | ? | ? |
| `sessionEnd` | ? | ? | ? |

### Step 2: Adjust input parsing

Each tool passes different JSON to hooks. Update the `jq` parsing in each script:

```bash
# Copilot passes: {"cwd": "...", "timestamp": "..."}
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Your tool might pass: {"workspaceRoot": "...", "time": "..."}
CWD=$(echo "$INPUT" | jq -r '.workspaceRoot // empty')
```

### Step 3: Rename the folder

Rename `hooks/copilot/` to match your tool's convention:
- Cursor: `hooks/cursor/`
- Windsurf: `hooks/windsurf/`
- Custom: `hooks/my-tool/`

### Step 4: Update hook registration

Replace `hooks.json` with your tool's hook registration format. The logic in the `.sh` scripts stays the same.

## Configuration

All thresholds are in `<workbenchRoot>/config.yaml`:

```yaml
session_extract:
  min_tool_calls: 3    # trigger mid-session extraction

dream:
  min_sessions: 5      # sessions before dream
  min_hours: 24        # hours before dream

integrations:
  mempalace:
    enabled: auto      # auto = detect on PATH, true = force on, false = force off
```

Scripts fall back to these defaults if config is missing.

## MemPalace Integration (Optional)

MemPalace is an optional enhancement that reduces token usage and improves retrieval quality.

**What it adds:**
- **Session start**: Uses `mempalace wake-up` for compact context instead of full MEMORY.md
- **Session end**: Indexes session notes with `mempalace mine` for semantic retrieval
- **Dream skill**: Prefers semantic search over grep when gathering signal

**Token savings:**
- Full MEMORY.md: ~2000-5000 tokens per session start
- MemPalace wake-up: ~200-500 tokens (L0+L1 facts only)

**How to enable:**
1. Set `integrations.mempalace.enabled: true` in config.yaml
2. MemPalace will auto-install on first use if not already present
3. Or manually install: https://github.com/MemPalace/mempalace

**Auto-installation:**
When `enabled: true`, the hooks will automatically install MemPalace to `~/.local/bin` if it's not found on PATH. This happens silently on first session start.

**How to disable:**
Set `integrations.mempalace.enabled: false` in config.yaml

**Fallback behavior:**
If MemPalace is enabled but any operation fails, hooks automatically fall back to the base file-system workflow. Failures never block the agent.

## Debugging

Test hooks manually by piping JSON:

```bash
echo '{"cwd": "/tmp/test", "timestamp": "2026-04-08T12:00:00Z"}' | ./session-start.sh
echo '{"toolName": "Write"}' | ./post-tool-use.sh
echo '{"reason": "complete"}' | ./session-end.sh
```

Check state files:
```bash
cat <workbenchRoot>/.tmp/current-session
cat <workbenchRoot>/.tmp/tool-count-*
cat <workbenchRoot>/.tmp/session-count
ls -la <workbenchRoot>/.tmp/extract-pending
```
