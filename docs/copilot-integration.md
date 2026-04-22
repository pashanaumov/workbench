# GitHub Copilot Integration Guide

Workbench integrates with GitHub Copilot through **two complementary mechanisms**:

1. **Skills** - Make workbench commands available to Copilot
2. **Hooks** - Automate memory loading and session management

In this guide, `<workbenchRoot>` means:
1. `WORKBENCH_ROOT` (if set)
2. `.workbench` in the current project (or nearest parent)
3. `~/.workbench` fallback

## Quick Start

```bash
# Install workbench
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash

# Install skills to Copilot
workbench copilot skills

# Install hooks for automation
workbench install copilot

# Add custom instructions
workbench print steering-doc >> .github/copilot-instructions.md
```

## Part 1: Skills Installation

Skills make workbench commands (`/skillify`, `/dream`, etc.) available to Copilot.

### Project-Specific Skills

```bash
workbench copilot skills
```

This creates symlinks in `.agents/skills/` pointing to `<workbenchRoot>/skills/`:
```
.agents/skills/
├── skillify -> <workbenchRoot>/skills/skillify
├── session-extract -> <workbenchRoot>/skills/session-extract
├── dream -> <workbenchRoot>/skills/dream
└── workbench -> <workbenchRoot>/skills/workbench
```

**Commit these to your repo** so team members get the same skills.

### Global Skills

```bash
workbench copilot skills --global
```

This creates symlinks in `~/.copilot/skills/` - available across all projects.

### Verification

```bash
# Check skills are installed
ls -la .agents/skills/
# or
ls -la ~/.copilot/skills/

# Each should show symlinks to <workbenchRoot>/skills/*
```

### Using Skills

Once installed, invoke skills in Copilot:
```
/skillify "the workflow we just did"
/session-extract
/dream
/workbench status
```

## Part 2: Hooks Installation

Hooks automate memory loading and session management.

### For Cloud Agent (GitHub.com)

```bash
# Install hooks
workbench install copilot

# Commit to default branch (required!)
git add .github/hooks/
git commit -m "Add workbench hooks"
git push
```

Hooks must be on the default branch to work with cloud agent.

### For Copilot CLI

```bash
# Install hooks (no commit needed)
workbench install copilot

# Works immediately from current directory
```

### What Hooks Do

**Session Start:**
- Load memory from `<workbenchRoot>/.tmp/active-memory.md`
- Check if dream consolidation is needed
- Reset tool counter

**Post-Tool-Use:**
- Count tool executions
- After 3 tools, flag for `/session-extract`

**Session End:**
- Flag for final extraction
- Increment session counter
- Clean up session state

### Hook Output

Hooks output visible messages:
```
🔧 [Workbench] Session starting...
🔧 [Workbench] Loading memory from <workbenchRoot>
✅ [Workbench] Session started successfully
```

**Where to see:**
- **VS Code**: Output panel → "GitHub Copilot"
- **CLI**: Direct terminal output

## Part 3: Custom Instructions

Add steering doc to tell Copilot how to use workbench:

### For Cloud Agent

```bash
workbench print steering-doc >> .github/copilot-instructions.md
git add .github/copilot-instructions.md
git commit -m "Add workbench instructions"
git push
```

### For CLI

**Option A:** Project-specific
```bash
workbench print steering-doc >> .github/copilot-instructions.md
```

**Option B:** Global
```bash
mkdir -p ~/.copilot
workbench print steering-doc >> ~/.copilot/copilot-instructions.md
```

**Option C:** AGENTS.md
```bash
workbench print steering-doc >> AGENTS.md
```

## Complete Setup Checklist

### Cloud Agent (GitHub.com)

- [ ] Install workbench: `curl -fsSL ... | bash`
- [ ] Install skills: `workbench copilot skills`
- [ ] Install hooks: `workbench install copilot`
- [ ] Add steering doc: `workbench print steering-doc >> .github/copilot-instructions.md`
- [ ] Commit everything to default branch
- [ ] Push to GitHub
- [ ] Test in GitHub Copilot

### CLI (`gh copilot`)

- [ ] Install workbench: `curl -fsSL ... | bash`
- [ ] Install skills: `workbench copilot skills` (or `--global`)
- [ ] Install hooks: `workbench install copilot`
- [ ] Add steering doc: `workbench print steering-doc >> AGENTS.md`
- [ ] Test with `gh copilot`

## Compatibility with `npx skills`

Workbench is compatible with Vercel's `skills` CLI:

```bash
# Alternative installation method
npx skills add /path/to/workbench --agent github-copilot

# Or from GitHub (once published)
npx skills add pashanaumov/workbench --agent github-copilot
```

This installs to the same locations:
- Project: `.agents/skills/`
- Global: `~/.copilot/skills/`

## Troubleshooting

### Skills not showing up

**Check installation:**
```bash
ls -la .agents/skills/
# Should show symlinks to <workbenchRoot>/skills/*
```

**Verify SKILL.md files:**
```bash
cat .agents/skills/skillify/SKILL.md
# Should show valid YAML frontmatter with name and description
```

**Try global installation:**
```bash
workbench copilot skills --global
```

### Hooks not executing

**Check hooks are installed:**
```bash
ls -la .github/hooks/copilot/
```

**Check hooks are executable:**
```bash
ls -la .github/hooks/copilot/*.sh
# Should show rwxr-xr-x permissions
```

**For cloud agent, verify on default branch:**
```bash
git branch --show-current
# Should be main/master
```

**Test manually:**
```bash
echo '{"cwd":"'$(pwd)'","timestamp":'$(date +%s)'}' | \
  .github/hooks/copilot/session-start.sh
```

### Memory not loading

**Check active memory file:**
```bash
cat <workbenchRoot>/.tmp/active-memory.md
```

**Check session started:**
```bash
cat <workbenchRoot>/.tmp/current-session
```

**Check steering doc is present:**
```bash
cat .github/copilot-instructions.md | grep -A5 "Workbench"
```

## Architecture

```
<workbenchRoot>/                    # Workbench installation
├── skills/                      # Source skills
│   ├── skillify/
│   ├── session-extract/
│   ├── dream/
│   └── workbench/
├── hooks/copilot/               # Hook templates
└── .tmp/                        # Runtime state
    ├── active-memory.md         # Loaded at session start
    ├── extract-pending          # Flag for extraction
    └── dream-pending            # Flag for consolidation

.agents/skills/                  # Copilot project skills
├── skillify -> <workbenchRoot>/skills/skillify
├── session-extract -> <workbenchRoot>/skills/session-extract
├── dream -> <workbenchRoot>/skills/dream
└── workbench -> <workbenchRoot>/skills/workbench

.github/
├── hooks/copilot/               # Installed hooks
│   ├── session-start.sh
│   ├── post-tool-use.sh
│   └── session-end.sh
└── copilot-instructions.md      # Steering doc

~/.copilot/                      # Global Copilot config
├── skills/                      # Global skills (optional)
└── copilot-instructions.md      # Global instructions (optional)
```

## Why Two Mechanisms?

**Skills** = What Copilot can do
- Makes `/skillify`, `/dream`, etc. available
- Discoverable in Copilot's skill list
- Can be invoked explicitly by user

**Hooks** = Automation
- Loads memory automatically at session start
- Triggers extraction after N tool uses
- Manages session lifecycle

**Custom Instructions** = How to use them
- Tells Copilot when to check for flags
- Explains memory system
- Provides context for skills

All three work together for the complete workbench experience.

## Next Steps

1. Complete the setup checklist above
2. Start a Copilot session and watch for hook messages
3. Try invoking `/skillify` or `/dream`
4. Check that memory loads at session start
5. Verify extraction triggers after 3 tool uses

## Further Reading

- [Hook Visibility Guide](./hook-visibility.md)
- [Copilot CLI Setup](./copilot-cli-setup.md)
- [Steering Doc Template](../templates/steering-doc-template.md)
- [GitHub Copilot Skills Docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
