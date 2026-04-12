# Workbench

Portable, tool-agnostic agent enhancement primitives — skills, hooks, memory files, and config that work across any AI coding tool.

Derived from Claude Code's `skillify`, `sessionMemory`, and `autoDream` systems, distilled into universal building blocks with no compilation step, no runtime dependency, and no tool-specific lock-in.

## What's Inside

```
workbench/
├── skills/              Three core skills (markdown prompts)
│   ├── skillify/        Capture workflows as reusable skills
│   ├── session-extract/ Extract structured session notes
│   └── dream/           Consolidate notes into long-term memory
├── hooks/               Automation glue (reference implementation)
│   └── copilot/         GitHub Copilot hooks + adaptation guide
├── memory/              Consolidated long-term memory files
│   └── MEMORY.md        Index of topic-based memory files
├── session-memory/      Per-session structured notes (runtime)
├── templates/           Templates for skills, notes, steering docs
├── .tmp/                Runtime state for hooks (runtime)
└── config.yaml          Configuration and thresholds
```

## Quick Start

### Installation

**Recommended (git clone):**

```bash
git clone https://github.com/yourusername/workbench ~/.workbench
cd ~/.workbench
./install.sh
```

**Fast path (curl):**

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/workbench/main/install.sh | bash
```

**Verify installation:**

```bash
# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.workbench/bin:$PATH"

# Check health
workbench doctor
```

### Setup

**1. Add Steering Doc**

Add the memory injection instructions to your AI tool's configuration:

```bash
# Print the steering doc snippet
workbench print steering-doc

# For Copilot, append to .github/copilot-instructions.md
workbench print steering-doc >> .github/copilot-instructions.md
```

See `templates/steering-doc-template.md` for other tools (Cursor, Windsurf, Kilo, Claude Code).

**2. Optional: Install Hooks**

For automatic session extraction and memory consolidation (GitHub Copilot):

```bash
# In your project directory
workbench install copilot

# Commit to default branch
git add .github/hooks/
git commit -m "Add workbench hooks"
git push
```

**3. Start Using**

The three core skills are now available:
- `/skillify` - Capture workflows as reusable skills
- `/session-extract` - Extract structured session notes
- `/dream` - Consolidate notes into long-term memory

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

## How It Works

**Skills** are markdown files with YAML frontmatter. Any agent that can read a file can use them.

**Hooks** (optional) automate when skills run. The Copilot implementation is a reference — see `hooks/copilot/hooks.README.md` for the pattern and how to adapt it for other tools.

**Memory** flows from session notes → dream consolidation → MEMORY.md index → injected into future sessions via steering doc.

**Without hooks**, you can still use workbench manually:
- Run `/session-extract` every 10-15 turns or at session end
- Run `/dream` after every 5-10 sessions

## Documentation

- **Steering doc setup**: `templates/steering-doc-template.md`
- **Hook installation**: `hooks/copilot/hooks.README.md`
- **Session note structure**: `templates/session-memory-template.md`
- **Skill authoring**: `templates/skill-template.md`
- **Configuration**: `config.yaml`

## CLI Commands

```bash
workbench init                      # Initialize workbench
workbench doctor                    # Check installation health
workbench print steering-doc        # Print steering doc snippet
workbench install copilot [dir]     # Install Copilot hooks
workbench mempalace status          # Check MemPalace status
```

## Requirements

- **Core skills**: None (just markdown and your AI tool)
- **Hooks**: Bash, basic Unix tools (`ls`, `grep`, `mkdir`)
- **Optional**: `jq` or `yq` for config parsing (falls back to grep/awk)
- **Optional**: [MemPalace](https://github.com/MemPalace/mempalace) for enhanced context loading

## License

[Add your license here]
