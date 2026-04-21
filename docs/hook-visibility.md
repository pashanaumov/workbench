# Hook Visibility & Debugging

Workbench hooks now output visible messages to stderr, mimicking Claude Code's hook execution feedback.

## Hook Messages

All hooks output messages to stderr (visible in terminal/console):

### Session Start Hook
```
🔧 [Workbench] Session starting...
🔧 [Workbench] Loading memory from ~/.workbench
✅ [Workbench] Session started successfully
```

If dream consolidation is pending:
```
🔧 [Workbench] Dream consolidation pending (5 sessions, 24h)
```

### Post-Tool-Use Hook
```
🔧 [Workbench] Tool executed, checking extraction threshold...
🔧 [Workbench] Tool count: 1/3
```

When threshold is reached:
```
✅ [Workbench] Extraction threshold reached (3/3 tools), flagging for /session-extract
```

### Session End Hook
```
🔧 [Workbench] Session ending, preparing final extraction...
✅ [Workbench] Session ended, extraction will run on next session start
```

## Where to See Hook Output

### GitHub Copilot (VS Code)
Hook output appears in:
- **Output panel** → "GitHub Copilot" channel
- **Developer Tools Console** (Help → Toggle Developer Tools)

### GitHub Copilot CLI
Hook output appears directly in your terminal:
```bash
gh copilot
# You'll see:
# 🔧 [Workbench] Session starting...
# 🔧 [Workbench] Loading memory from ~/.workbench
# ✅ [Workbench] Session started successfully
```

## Debugging Hooks

### Test hooks manually

**Session Start:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)'}' | \
  .github/hooks/copilot/session-start.sh
```

**Post-Tool-Use:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)',"toolName":"bash","toolArgs":"{}"}' | \
  .github/hooks/copilot/post-tool-use.sh
```

**Session End:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)'}' | \
  .github/hooks/copilot/session-end.sh
```

### Check hook execution

**Verify hooks are being called:**
```bash
# Add debug logging to hooks
export WORKBENCH_DEBUG=1

# Check if hooks ran
ls -la ~/.workbench/.tmp/
# Should see: current-session, active-memory.md, tool-count-*, etc.
```

**Check hook permissions:**
```bash
ls -la .github/hooks/copilot/*.sh
# All should be executable (rwxr-xr-x)
```

**Verify hooks.json:**
```bash
cat .github/hooks/copilot/hooks.json | jq .
# Should show valid JSON with sessionStart, postToolUse, sessionEnd
```

## Comparison with Claude Code

| Feature | Claude Code | Workbench (Copilot) |
|---------|-------------|---------------------|
| Hook events | `started`, `progress`, `response` | stderr messages with emoji |
| Visibility | Debug log + minimal UI | Terminal/console output |
| Success messages | Silent (null render) | ✅ confirmation |
| Error messages | Red error line | ✅/🔧 with context |
| Progress updates | Streaming output | Per-hook completion |

## Hook Execution Flow

```
Session Start
  ↓
🔧 Session starting...
  ↓
Load memory → active-memory.md
  ↓
Check dream gate
  ↓
✅ Session started
  ↓
[User interacts with agent]
  ↓
Tool executed
  ↓
🔧 Tool executed, checking threshold...
  ↓
Increment counter (1/3, 2/3, 3/3)
  ↓
If threshold reached:
  ✅ Extraction threshold reached
  Write .tmp/extract-pending
  ↓
[Agent checks flag, runs /session-extract]
  ↓
Session End
  ↓
🔧 Session ending...
  ↓
Write .tmp/extract-pending (final)
Increment session count
  ↓
✅ Session ended
```

## Troubleshooting

### Hooks not showing output

**VS Code:**
1. Open Output panel (View → Output)
2. Select "GitHub Copilot" from dropdown
3. Look for 🔧 and ✅ messages

**CLI:**
- Output should appear directly in terminal
- If not visible, check stderr redirection

### Hooks not executing

**Check hooks are installed:**
```bash
ls -la .github/hooks/copilot/
```

**Check hooks.json is valid:**
```bash
cat .github/hooks/copilot/hooks.json | jq .
```

**Test manually:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)'}' | \
  .github/hooks/copilot/session-start.sh 2>&1
```

### No memory loading

**Check active-memory.md:**
```bash
cat ~/.workbench/.tmp/active-memory.md
```

**Check session-start hook ran:**
```bash
cat ~/.workbench/.tmp/current-session
# Should show session key like: myproject-12345678
```

## Advanced: Custom Hook Messages

You can customize hook messages by editing the hook scripts:

```bash
# In session-start.sh, change:
echo "🔧 [Workbench] Session starting..." >&2

# To:
echo "🚀 [MyProject] Initializing..." >&2
```

All messages use stderr (`>&2`) so they don't interfere with hook JSON output.

## Emoji Reference

- 🔧 - Hook is running/processing
- ✅ - Hook completed successfully
- ⚠️ - Warning or non-critical issue
- ❌ - Error (not currently used, hooks fail silently)

## Next Steps

1. Run a Copilot session and watch for hook messages
2. Verify memory loads at session start
3. Trigger extraction by using 3+ tools
4. Check that session notes are created
5. Run `/dream` after 5+ sessions
