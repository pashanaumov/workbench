# Copilot CLI Setup Guide

This guide covers setting up workbench with GitHub Copilot CLI (`gh copilot`).

In this guide, `<workbenchRoot>` means:
1. `WORKBENCH_ROOT` (if set)
2. `.workbench` in the current project (or nearest parent)
3. `~/.workbench` fallback

## Key Differences from Cloud Agent

| Feature | Cloud Agent | CLI |
|---------|-------------|-----|
| Hooks location | `.github/hooks/` (default branch) | `.github/hooks/` (current directory) |
| Custom instructions | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` or `AGENTS.md` |
| Requires commit | Yes (must be on default branch) | No (loads from working directory) |
| Global instructions | Not supported | `~/.copilot/copilot-instructions.md` |

## Setup Steps

### 1. Install Workbench

```bash
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash
```

The installer will:
- Install to a chosen root (`~/.workbench` or `.workbench`)
- Add to your PATH (global install only)
- Prompt for MemPalace integration

### 2. Install Hooks (Optional but Recommended)

In your project directory:

```bash
workbench install copilot
```

This creates `.github/hooks/copilot/` with:
- `session-start.sh` - Loads memory at session start
- `post-tool-use.sh` - Triggers session extraction
- `session-end.sh` - Triggers dream consolidation
- `hooks.json` - Hook configuration

**No need to commit** - CLI loads hooks from your current working directory.

### 3. Add Custom Instructions

Choose one of these options:

**Option A: Project-specific (recommended)**

```bash
workbench print steering-doc >> .github/copilot-instructions.md
```

**Option B: Using AGENTS.md**

```bash
workbench print steering-doc >> AGENTS.md
```

**Option C: Global instructions**

```bash
mkdir -p ~/.copilot
workbench print steering-doc >> ~/.copilot/copilot-instructions.md
```

### 4. Verify Setup

```bash
# Check workbench health
workbench doctor

# Start a Copilot CLI session
gh copilot

# Ask: "What's in my active memory?"
# Agent should read <workbenchRoot>/.tmp/active-memory.md
```

## How It Works

### Session Flow

1. **Session starts** → `session-start.sh` runs
   - Loads `<workbenchRoot>/.tmp/active-memory.md`
   - Checks if dream consolidation is needed
   - Resets tool counter

2. **After each tool use** → `post-tool-use.sh` runs
   - Increments tool counter
   - After 3 tool calls, writes `.tmp/extract-pending` flag
   - Agent checks flag and runs `/session-extract`

3. **Session ends** → `session-end.sh` runs
   - Writes `.tmp/extract-pending` for final extraction
   - Increments session counter
   - Cleans up session state

### Custom Instructions

The steering doc tells the agent:
- Read memory file at session start
- Check for pending flags after each tool use
- Run skills when flags are present
- Delete flags after running skills

## Manual Mode (Without Hooks)

If you prefer not to use hooks:

1. Add custom instructions only (skip hook installation)
2. Manually run skills:
   - `/session-extract` - Every 10-15 turns or at session end
   - `/dream` - After every 5-10 sessions

## Troubleshooting

### Hooks not executing

**Check hook location:**
```bash
ls -la .github/hooks/copilot/
```

**Verify hooks are executable:**
```bash
chmod +x .github/hooks/copilot/*.sh
```

**Check hooks.json syntax:**
```bash
cat .github/hooks/copilot/hooks.json | jq .
```

### Custom instructions not loading

**Verify file exists:**
```bash
ls -la .github/copilot-instructions.md
# or
ls -la AGENTS.md
```

**Check file content:**
```bash
cat .github/copilot-instructions.md
```

**Try global instructions:**
```bash
mkdir -p ~/.copilot
workbench print steering-doc > ~/.copilot/copilot-instructions.md
```

### Memory not loading

**Check active memory file:**
```bash
cat <workbenchRoot>/.tmp/active-memory.md
```

**Verify session-start hook ran:**
```bash
ls -la <workbenchRoot>/.tmp/current-session
```

**Run hook manually to test:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)'}' | .github/hooks/copilot/session-start.sh
```

### Skills not triggering

**Check for pending flags:**
```bash
ls -la <workbenchRoot>/.tmp/*-pending
```

**Verify skills exist:**
```bash
ls -la <workbenchRoot>/skills/
```

**Test skill manually:**
```bash
# In your AI tool
/session-extract
```

## Advanced Configuration

### Change tool call threshold

Edit `<workbenchRoot>/config.yaml`:

```yaml
session_extract:
  min_tool_calls: 5  # Default is 3
```

### Disable automatic dream

```bash
/workbench dream off
```

### Switch to hybrid mode

```bash
/workbench mode hybrid
```

This allows project-specific `.workbench/` to override global settings.

## Comparison with Cloud Agent

### Advantages of CLI

- No need to commit hooks to repository
- Works immediately in any directory
- Can use global instructions
- Faster iteration during development

### Advantages of Cloud Agent

- Hooks are version controlled
- Team members get same setup automatically
- Works in GitHub web interface
- Integrated with GitHub features

## Next Steps

1. Use workbench for a few sessions
2. Run `/dream` to consolidate memory
3. Create custom skills with `/skillify`
4. Configure settings with `/workbench`

## Further Reading

- [Hooks configuration reference](https://docs.github.com/en/copilot/reference/hooks-configuration)
- [Custom instructions guide](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [Copilot CLI documentation](https://docs.github.com/en/copilot/how-tos/copilot-cli)
