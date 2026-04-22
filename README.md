# Workbench

Portable, tool-agnostic agent enhancement primitives — skills, hooks, memory files, config, and a production-ready workspace indexer that work across AI coding tools.

Derived from Claude Code's `skillify`, `sessionMemory`, and `autoDream` systems, distilled into universal building blocks with no compilation step, no runtime dependency, and no tool-specific lock-in.

✅ **Workspace indexing is ready to use now** via `workbench index`, `workbench search`, and `workbench status` (with optional MCP integration for Claude Code via `workbench indexer enable`).

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
- **Global** (`~/.workbench`) - Available across all projects
- **Local** (`.workbench`) - Only in current project

**Non-interactive:**

```bash
# Global installation
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- ~/.workbench

# Local installation
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- .workbench
```

The installer will:
- Install workbench files to chosen location
- Add to PATH automatically (global only)
- Prompt you to enable MemPalace integration (optional)

**Verify installation:**

```bash
# For global installation
wb doctor

# For local installation
.workbench/bin/wb doctor
```

### Setup

The installer handles everything — after installing files it will ask which AI tool you use and automatically:
- Install hooks (for Copilot)
- Add the steering doc to the right config file

If you need to set up a different tool later:

```bash
wb install copilot        # installs hooks + steering doc for Copilot
```

Or manually add the steering doc for tools without hooks (Cursor, Windsurf, Kiro):

```
/workbench setup
```

### Workspace Indexing (Ready Now)

Index your project and run hybrid semantic + keyword search immediately:

```bash
workbench index .                    # Build or incrementally update index
workbench search "auth token flow"   # Search code chunks by meaning + terms
workbench status                     # Check index health for current project
```

For Claude Code MCP auto-integration:

```bash
workbench indexer enable             # Register workbench-indexer MCP server
workbench indexer status             # Verify registration + project index state
```

## Core Capabilities

### `/skillify`

Capture the workflow you just performed as a reusable skill. Analyzes the session, interviews you about the process, and writes a `SKILL.md` file you can invoke in future sessions.

```bash
/skillify "the cherry-pick workflow we just did"
```

### `/session-extract`

Extract structured notes from the current session into a persistent markdown file. Preserves context across compactions and sessions.

```bash
/session-extract
```

### `/dream`

Consolidate recent session notes into durable, topic-based memory files. Makes the agent progressively more aware of your preferences and working patterns.

```bash
/dream
```

### `/workbench`

Configure workbench settings interactively.

```bash
/workbench setup               # Add steering doc to your AI tool's config
/workbench status              # Show current configuration
/workbench mode hybrid         # Switch to hybrid mode
/workbench mempalace on        # Enable MemPalace integration
/workbench dream off           # Disable automatic dream consolidation
/workbench config              # Show full config
/workbench config set dream.min_sessions 3  # Update a setting
```

## Modes

Workbench supports three modes:

- **global** (default): Only use `~/.workbench/` for skills, memory, and config
- **local**: Only use `.workbench/` in project root (per-project isolation)
- **hybrid**: Check both locations, project-local overrides global

Switch modes with `/workbench mode <global|local|hybrid>`.

## How It Works

**Skills** are markdown files with YAML frontmatter. Any agent that can read a file can use them.

**Hooks** (optional) automate when skills run. The Copilot implementation is a reference — see `hooks/copilot/hooks.README.md` for the pattern and how to adapt it for other tools.

**Memory** flows from session notes → dream consolidation → MEMORY.md index → injected into future sessions via steering doc.

**Background behavior**: Memory loads automatically and silently at session start — no chat announcements. Hook diagnostic output (🔧/✅) appears in your terminal stderr so you can see workbench is active.

**Without hooks**, you can still use workbench manually:
- Run `/session-extract` every 10-15 turns or at session end
- Run `/dream` after every 5-10 sessions

## Tool Support

### GitHub Copilot (Cloud Agent)

- **Hooks**: ✓ (via `.github/hooks/`, must be on default branch)
- **Custom instructions**: ✓ (via `.github/copilot-instructions.md`)
- **Setup**: `workbench install copilot` + commit to default branch

### GitHub Copilot CLI

- **Hooks**: ✓ (via `.github/hooks/` in current working directory)
- **Custom instructions**: ✓ (via `.github/copilot-instructions.md` or `AGENTS.md`)
- **Setup**: `workbench install copilot` (no commit needed)

### Cursor / Windsurf

- **Hooks**: ✗ (manual workflow)
- **Custom instructions**: ✓ (via `.cursorrules` or `.windsurfrules`)
- **Setup**: Add steering doc to rules file

### Kilo / Claude Code

- **Hooks**: ✗ (manual workflow)
- **Custom instructions**: ✓ (via `AGENTS.md`)
- **Setup**: Add steering doc to AGENTS.md

## MemPalace Integration

MemPalace provides enhanced context loading and semantic memory search.

**Enable during installation:**
The installer will prompt you to enable MemPalace.

**Enable after installation:**
```bash
/workbench mempalace on
```

**Install MemPalace:**
```bash
npm install -g @mempalace/cli
# or
brew install mempalace
```

**Check status:**
```bash
workbench mempalace status
```

## CLI Commands

```bash
workbench init                      # Initialize workbench
workbench doctor                    # Check installation health
workbench print steering-doc        # Print steering doc snippet
workbench install copilot [dir]     # Install Copilot hooks
workbench copilot skills [--global] # Install skills to Copilot
workbench index [path]              # Index codebase
workbench search <query> [--top N]  # Search indexed code (semantic + keyword)
workbench status                    # Show index status for current directory
workbench clear                     # Remove current project's index
workbench indexer enable [path]     # Register indexer MCP with Claude Code
workbench indexer disable           # Disable indexer MCP
workbench indexer status            # Show MCP registration + index state
workbench mempalace status          # Check MemPalace status

# Short alias: wb
wb doctor                           # Same as workbench doctor
wb copilot skills                   # Same as workbench copilot skills
```

## Requirements

- **Core skills**: None (just markdown and your AI tool)
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
