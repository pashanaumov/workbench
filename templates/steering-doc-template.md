# Workbench Memory Integration

Add the following instructions to your AI coding tool's configuration to enable automatic memory loading and skill triggering.

## Core Instructions

Add this to your tool's steering document or system prompt:

```markdown
## Agent Memory

At the start of every session, read `~/.workbench/.tmp/active-memory.md`.
This file contains consolidated notes about preferences, projects, and
working patterns. If the file is empty or missing, continue normally.

If `.workbench/.tmp/extract-pending` exists:
1. Run the `/session-extract` skill to capture notes from the last session
2. Delete `.workbench/.tmp/extract-pending`

If `.workbench/.tmp/dream-pending` exists:
1. Run the `/dream` skill to consolidate memory
2. Delete `.workbench/.tmp/dream-pending`
```

## Tool-Specific Placement

### GitHub Copilot

Add the core instructions to `.github/copilot-instructions.md` in your repository:

```bash
# Create or append to the file
cat >> .github/copilot-instructions.md << 'EOF'

## Agent Memory
[paste core instructions above]
EOF
```

### Kilo Code / Claude Code

**Option 1:** Add to your project's `AGENTS.md` or `CLAUDE.md` file:

```bash
cat >> AGENTS.md << 'EOF'

## Agent Memory
[paste core instructions above]
EOF
```

**Option 2:** Add the memory file path to your tool's config:

```json
{
  "instructions": [
    "~/.workbench/.tmp/active-memory.md"
  ]
}
```

### Cursor / Windsurf

Add to `.cursorrules` or `.windsurfrules` in your project root:

```bash
cat >> .cursorrules << 'EOF'

## Agent Memory
[paste core instructions above]
EOF
```

### Other Tools

For any tool that supports custom system prompts or persistent instructions:

1. Locate where your tool reads custom instructions (usually a dotfile in project root or home directory)
2. Add the core instructions block above
3. Ensure the tool can read files from `~/.workbench/.tmp/`

## Verification

After adding the instructions:

1. Start a new agent session
2. Ask: "What's in my active memory?"
3. The agent should read `~/.workbench/.tmp/active-memory.md` and report its contents
4. If the file doesn't exist yet, the agent should say so without error

## Without Hooks

If your tool doesn't support hooks (automatic triggering), you can still use workbench manually:

- Run `/session-extract` periodically during long sessions (every 10-15 turns)
- Run `/session-extract` at the end of each session
- Run `/dream` after every 5-10 sessions to consolidate memory

The steering doc instructions above will still work for flag-based triggering if you set up hooks later.
