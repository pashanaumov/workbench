# Workbench Memory Integration

Add these instructions to your AI tool's configuration to enable automatic memory loading and skill execution.

## For GitHub Copilot (Cloud Agent & CLI)

### Cloud Agent Setup

Add to `.github/copilot-instructions.md` in your repository (must be on default branch):

```markdown
## Workbench Memory System

**On every session start:**
1. Run: `cat ~/.workbench/.tmp/active-memory.md 2>/dev/null || echo "No memory loaded"`
2. If file exists and has content, acknowledge: "Loaded workbench memory"
3. If file doesn't exist or is empty, continue silently

**After every tool execution:**
1. Run: `test -f ~/.workbench/.tmp/extract-pending && echo "EXTRACT_PENDING" || echo ""`
2. If output is "EXTRACT_PENDING":
   - Run the `/session-extract` skill
   - Run: `rm ~/.workbench/.tmp/extract-pending`

**On session end:**
1. Run: `test -f ~/.workbench/.tmp/dream-pending && echo "DREAM_PENDING" || echo ""`
2. If output is "DREAM_PENDING":
   - Run the `/dream` skill
   - Run: `rm ~/.workbench/.tmp/dream-pending`
```

### CLI Setup

For `gh copilot` CLI, add to **either**:

**Option 1:** `.github/copilot-instructions.md` in your project (same content as above)

**Option 2:** `AGENTS.md` in your project root (same content as above)

**Option 3:** `~/.copilot/copilot-instructions.md` for global instructions

The CLI loads hooks from `.github/hooks/` in your current working directory.

## For Cursor / Windsurf

Add to `.cursorrules` or `.windsurfrules` in project root:

```markdown
## Workbench Memory System

**On every session start:**
1. Read `~/.workbench/.tmp/active-memory.md`
2. If file exists and has content, acknowledge: "Loaded workbench memory"
3. If file doesn't exist, continue silently

**Check for pending tasks:**
1. If `~/.workbench/.tmp/extract-pending` exists:
   - Run `/session-extract` skill
   - Delete the flag file
2. If `~/.workbench/.tmp/dream-pending` exists:
   - Run `/dream` skill
   - Delete the flag file
```

## For Kilo / Claude Code

Add to `AGENTS.md` in project root:

```markdown
## Workbench Memory System

**On every session start:**
1. Read `~/.workbench/.tmp/active-memory.md`
2. If file exists and has content, acknowledge: "Loaded workbench memory"

**Check for pending tasks:**
1. If `~/.workbench/.tmp/extract-pending` exists:
   - Run `/session-extract` skill
   - Delete the flag file
2. If `~/.workbench/.tmp/dream-pending` exists:
   - Run `/dream` skill
   - Delete the flag file
```

## Verification

After adding instructions, test that they work:

1. Start a new session
2. Ask: "What's in my active memory?"
3. Agent should read `~/.workbench/.tmp/active-memory.md` and report contents
4. If file doesn't exist, agent should say so without error

## Without Hooks (Manual Mode)

If your tool doesn't support hooks, run these manually:

- `/session-extract` - Every 10-15 turns or at session end
- `/dream` - After every 5-10 sessions

The steering doc instructions will still work for flag-based triggering if you set up hooks later.

## Troubleshooting

**Memory not loading:**
- Verify file exists: `ls -la ~/.workbench/.tmp/active-memory.md`
- Check file permissions: `cat ~/.workbench/.tmp/active-memory.md`
- Ensure steering doc is in the correct location for your tool

**Skills not triggering:**
- Verify hooks are installed: `ls -la .github/hooks/`
- Check hook permissions: `ls -la .github/hooks/copilot/*.sh`
- Run `workbench doctor` to verify installation

**Copilot CLI not using instructions:**
- Ensure file is in current working directory
- Try `AGENTS.md` if `.github/copilot-instructions.md` doesn't work
- Check `~/.copilot/copilot-instructions.md` for global instructions
