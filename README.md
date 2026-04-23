# Workbench

Portable, tool-agnostic agent enhancement primitives — skills, hooks, memory files, and config that work across AI coding tools.

Derived from Claude Code's `skillify`, `sessionMemory`, and `autoDream` systems, distilled into universal building blocks with no compilation step, no runtime dependency, and no tool-specific lock-in.

## What's Inside

```
workbench/
├── skills/              Core skills (markdown prompts)
│   ├── skillify/        Capture workflows as reusable skills
│   ├── session-extract/ Extract structured session notes
│   ├── dream/           Consolidate notes into long-term memory
│   └── workbench/       Configure workbench settings
├── hooks/               Automation glue (reference implementation)
│   └── copilot/         GitHub Copilot hooks + adaptation guide
├── memory/              Consolidated long-term memory files
│   └── MEMORY.md        Index of topic-based memory files
├── session-memory/      Per-session structured notes (runtime)
├── templates/           Templates for skills, notes, steering docs
├── bin/workbench        CLI tool for management
└── config.yaml          Configuration and thresholds
```

## Quick Start

### Installation

**Interactive (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash
```

You'll be prompted to choose:
- **Global** (`~/.workbench`) — Available across all projects
- **Local** (`.workbench`) — Only in current project

**Non-interactive:**

```bash
# Global
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- ~/.workbench

# Local
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- .workbench

# Fully scripted
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh \
  | bash -s -- --non-interactive --target .workbench --agent copilot --scope project --mempalace later
```

**Verify:**

```bash
workbench doctor          # global install
.workbench/bin/workbench doctor  # local install
```

### Setup

The installer handles everything — after installing it will ask which AI tool you use and automatically install hooks and add the steering doc.

To set up a different tool later:

```bash
workbench install copilot        # installs hooks + steering doc for Copilot
```

Or manually for tools without hooks (Cursor, Windsurf, Kiro):

```
/workbench setup
```

## Core Capabilities

### `/skillify`

Capture the workflow you just performed as a reusable skill. Analyzes the session, interviews you about the process, and writes a `SKILL.md` you can invoke in future sessions.

```
/skillify "the cherry-pick workflow we just did"
```

### `/session-extract`

Extract structured notes from the current session into a persistent markdown file. Preserves context across compactions and sessions.

```
/session-extract
```

### `/dream`

Consolidate recent session notes into durable, topic-based memory files. Makes the agent progressively more aware of your preferences and working patterns.

```
/dream
```

### `/workbench`

Configure workbench settings interactively.

```
/workbench setup               # Add steering doc to your AI tool's config
/workbench status              # Show current configuration
/workbench mode hybrid         # Switch to hybrid mode
/workbench mempalace on        # Enable MemPalace integration
/workbench dream off           # Disable automatic dream consolidation
/workbench config              # Show full config
/workbench config set dream.min_sessions 3
```

## Semantic Code Search

Semantic search has been extracted into a standalone Claude Code plugin: **[scope](https://github.com/pashanaumov/scope)**.

```bash
claude plugin marketplace add pashanaumov/scope
claude plugin install scope@marketplace
```

This provides MCP tools (`index_codebase`, `search_code`, `get_indexing_status`, `clear_index`) and slash commands (`/scope:index`, `/scope:search`, `/scope:status`, `/scope:clear`).

## Modes

- **global** (default): Only use `~/.workbench/` for skills, memory, and config
- **local**: Only use `.workbench/` in project root
- **hybrid**: Check both; project-local overrides global

Switch with `/workbench mode <global|local|hybrid>`.

## How It Works

**Skills** are markdown files with YAML frontmatter. Any agent that can read a file can use them.

**Hooks** (optional) automate when skills run. The Copilot implementation is a reference — see `hooks/copilot/hooks.README.md` for the pattern and how to adapt it for other tools.

**Memory** flows from session notes → dream consolidation → MEMORY.md index → injected into future sessions via steering doc.

**Background behavior**: Memory loads automatically and silently at session start. Hook diagnostic output (🔧/✅) appears in stderr so you can see workbench is active.

**Without hooks**, use workbench manually:
- `/session-extract` every 10–15 turns or at session end
- `/dream` after every 5–10 sessions

## Tool Support

| Tool | Hooks | Custom instructions | Setup |
|------|-------|--------------------|----|
| **Copilot Cloud Agent** | ✓ via `.github/hooks/` (must be on default branch) | ✓ `.github/copilot-instructions.md` | `workbench install copilot` + commit |
| **Copilot CLI** | ✓ via `.github/hooks/` | ✓ `.github/copilot-instructions.md` or `AGENTS.md` | `workbench install copilot` |
| **Cursor / Windsurf** | ✗ manual | ✓ `.cursorrules` / `.windsurfrules` | Add steering doc to rules file |
| **Kiro / Claude Code** | ✗ manual | ✓ `AGENTS.md` | Add steering doc to AGENTS.md |

## MemPalace Integration

Enhanced context loading and semantic memory search.

```bash
# Enable
/workbench mempalace on

# Install
npm install -g @mempalace/cli

# Status
workbench mempalace status
```

## CLI Commands

```bash
workbench init                      # Initialize workbench
workbench doctor                    # Check installation health
workbench print steering-doc        # Print steering doc snippet
workbench install copilot [dir]     # Install Copilot hooks
workbench copilot skills [--global] # Install skills to Copilot
workbench mempalace status          # Check MemPalace status
```

## Requirements

- **Core skills**: None — just markdown and your AI tool
- **Hooks**: Bash, basic Unix tools (`ls`, `grep`, `mkdir`)
- **Optional**: `jq` or `yq` for config parsing (falls back to grep/awk)
- **Optional**: [MemPalace](https://github.com/MemPalace/mempalace) for enhanced context loading

## Documentation

- **Steering doc setup**: `templates/steering-doc-template.md`
- **Hook installation**: `hooks/copilot/hooks.README.md`
- **Copilot CLI setup**: `docs/copilot-cli-setup.md`
- **Session note structure**: `templates/session-memory-template.md`
- **Skill authoring**: `templates/skill-template.md`
- **Configuration**: `config.yaml`

## License

MIT © Pasha Naumov

