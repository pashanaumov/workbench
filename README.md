# Workbench

Portable, tool-agnostic agent enhancement primitives — skills, hooks, memory files, and config that work across AI coding tools. No compilation step, no runtime dependency, no tool-specific lock-in.

Derived from Claude Code's `skillify`, `sessionMemory`, and `autoDream` systems, distilled into universal building blocks.

> **Semantic code search?** See the [scope plugin](https://github.com/pashanaumov/scope) — a standalone Claude Code plugin that indexes your codebase with ONNX embeddings + LanceDB and exposes it via MCP.

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
# Global installation
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- ~/.workbench

# Local installation
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh | bash -s -- .workbench

# Fully non-interactive (good for scripts/agents)
curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench/main/install.sh \
  | bash -s -- --non-interactive --target .workbench --agent copilot --scope project --mempalace later
```

The installer will:
- Copy workbench files to the chosen location
- Add `~/.workbench/bin` to PATH automatically (global install only)
- Prompt for MemPalace integration (optional)
- Set up agent integration (hooks, steering doc) for your AI tool

**Verify installation:**

```bash
workbench doctor          # global install
.workbench/bin/workbench doctor  # local install
```

### Setup

The installer handles everything — it asks which AI tool you use and automatically installs hooks and adds the steering doc.

To set up a different tool after installation:

```bash
workbench install copilot        # hooks + steering doc for Copilot
```

Or manually add the steering doc for tools without hooks (Cursor, Windsurf, Kiro, Claude Code):

```
/workbench setup
```

## Core Capabilities

### `/skillify`

Capture the workflow you just performed as a reusable skill. Analyzes the session, interviews you about the process, and writes a `SKILL.md` file you can invoke in future sessions.

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

## Modes

- **global** (default): Use `~/.workbench/` for all skills, memory, and config
- **local**: Use `.workbench/` in project root (per-project isolation)
- **hybrid**: Check both; project-local overrides global

Switch with `/workbench mode <global|local|hybrid>`.

## How It Works

**Skills** are markdown files with YAML frontmatter. Any agent that can read a file can use them.

**Hooks** (optional) automate when skills run. The Copilot implementation is a reference — see `hooks/copilot/hooks.README.md` for the pattern and how to adapt it for other tools.

**Memory** flows: session notes → `/dream` consolidation → `MEMORY.md` index → injected into future sessions via steering doc.

**Background behavior**: Memory loads silently at session start. Hook diagnostic output (🔧/✅) appears in stderr — intentional, shows workbench is active.

**Without hooks**, use manually:
- `/session-extract` every 10–15 turns or at session end
- `/dream` after every 5–10 sessions

## Tool Support

| Tool | Hooks | Custom instructions | Setup |
|------|-------|---------------------|-------|
| GitHub Copilot (cloud) | ✓ via `.github/hooks/` (commit required) | ✓ `.github/copilot-instructions.md` | `workbench install copilot` |
| GitHub Copilot CLI | ✓ via `.github/hooks/` | ✓ `.github/copilot-instructions.md` or `AGENTS.md` | `workbench install copilot` |
| Cursor | ✗ manual | ✓ `.cursorrules` | Add steering doc to rules file |
| Windsurf | ✗ manual | ✓ `.windsurfrules` | Add steering doc to rules file |
| Kiro / Claude Code | ✗ manual | ✓ `AGENTS.md` | Add steering doc to AGENTS.md |

## Semantic Code Search

For semantic codebase search, install the [scope plugin](https://github.com/pashanaumov/scope):

```bash
claude plugin marketplace add pashanaumov/scope
claude plugin install scope@marketplace
```

Scope provides:
- Hybrid vector + keyword search via MCP (`index_codebase`, `search_code`, `get_indexing_status`, `clear_index`)
- Slash commands: `/scope:index`, `/scope:search`, `/scope:status`, `/scope:clear`
- Local ONNX embeddings (no API key required) or OpenAI / Ollama backends
- Per-project incremental indexing stored in `~/.config/scope/`

## MemPalace Integration

MemPalace provides enhanced context loading and semantic memory search.

**Enable after installation:**
```bash
/workbench mempalace on
```

**Install MemPalace:**
```bash
npm install -g @mempalace/cli   # or: brew install mempalace
```

**Check status:**
```bash
workbench mempalace status
```

## CLI Reference

```bash
workbench init                       # Initialize workbench
workbench doctor                     # Check installation health
workbench print steering-doc         # Print steering doc snippet
workbench install copilot [dir]      # Install Copilot hooks + steering doc
workbench copilot skills [--global]  # Sync skills to Copilot skills directory
workbench mempalace status           # Check MemPalace status
```

## Requirements

- **Core**: None — pure bash and markdown
- **Hooks**: Bash, basic Unix tools (`ls`, `grep`, `mkdir`)
- **Optional**: `jq` or `yq` for config parsing (falls back to grep/awk)
- **Optional**: [MemPalace](https://github.com/MemPalace/mempalace) for enhanced context loading

## Documentation

- `templates/steering-doc-template.md` — steering doc reference
- `hooks/copilot/hooks.README.md` — hook installation and adaptation guide
- `templates/session-memory-template.md` — session note structure
- `templates/skill-template.md` — skill authoring guide
- `config.yaml` — configuration reference

## License

MIT © Pasha Naumov
