# Workbench Memory Integration

Add these instructions to your AI tool's configuration to enable automatic memory loading and skill execution.

## For GitHub Copilot (Cloud Agent & CLI)

### Cloud Agent Setup

Add to `.github/copilot-instructions.md` in your repository (must be on default branch):

```markdown
## Workbench Memory System

**On every session start (automatic, silent):**
1. Silently run: `cat ~/.workbench/.tmp/active-memory.md 2>/dev/null`
2. If file exists and has content, load it into context without announcing
3. This memory is now part of your working context for the session
4. Note: Hook output (🔧/✅ emojis) will appear in stderr - this is expected and helpful for debugging

**After every tool execution (automatic, silent):**
1. Silently check: `test -f ~/.workbench/.tmp/extract-pending && echo "EXTRACT_PENDING"`
2. If output is "EXTRACT_PENDING":
   - Silently run the `/session-extract` skill
   - Silently run: `rm ~/.workbench/.tmp/extract-pending`
3. Note: Hook output (🔧/✅ emojis) will appear in stderr - this is expected

**On session end (automatic, silent):**
1. Silently check: `test -f ~/.workbench/.tmp/dream-pending && echo "DREAM_PENDING"`
2. If output is "DREAM_PENDING":
   - Silently run the `/dream` skill
   - Silently run: `rm ~/.workbench/.tmp/dream-pending`
3. Note: Hook output (🔧/✅ emojis) will appear in stderr - this is expected

**Important:** 
- All workbench operations should happen silently in the background (no chat announcements)
- Hook diagnostic output (🔧/✅) to stderr is intentional and should remain visible
- Never announce "Loading memory" or "Running extract" in chat unless the user explicitly asks about workbench status
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

**On every session start (automatic, silent):**
1. Silently read `~/.workbench/.tmp/active-memory.md`
2. If file exists and has content, load it into context without announcing
3. This memory is now part of your working context for the session

**Check for pending tasks (automatic, silent):**
1. If `~/.workbench/.tmp/extract-pending` exists:
   - Silently run `/session-extract` skill
   - Delete the flag file
2. If `~/.workbench/.tmp/dream-pending` exists:
   - Silently run `/dream` skill
   - Delete the flag file

**Important:** 
- All workbench operations should happen silently in the background (no chat announcements)
- Tool/skill output may include diagnostic emojis (🔧/✅) - this is expected and helpful
- Never announce "Loading memory" or "Running extract" in chat unless the user explicitly asks about workbench status
```

## For Kilo / Claude Code

Add to `AGENTS.md` in project root:

```markdown
## Workbench Memory System

**On every session start (automatic, silent):**
1. Silently read `~/.workbench/.tmp/active-memory.md`
2. If file exists and has content, load it into context without announcing
3. This memory is now part of your working context for the session

**Check for pending tasks (automatic, silent):**
1. If `~/.workbench/.tmp/extract-pending` exists:
   - Silently run `/session-extract` skill
   - Delete the flag file
2. If `~/.workbench/.tmp/dream-pending` exists:
   - Silently run `/dream` skill
   - Delete the flag file

**Important:** 
- All workbench operations should happen silently in the background (no chat announcements)
- Tool/skill output may include diagnostic emojis (🔧/✅) - this is expected and helpful
- Never announce "Loading memory" or "Running extract" in chat unless the user explicitly asks about workbench status
```

## Verification

After adding instructions, test that they work:

1. Start a new session
2. Memory loads automatically and silently in the background
3. To verify it's working, check the file: `cat ~/.workbench/.tmp/active-memory.md`
4. Or ask the agent: "What preferences or context do you have about me?"
5. The agent should have access to your memory without you explicitly loading it

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
