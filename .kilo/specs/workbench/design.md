# Design

## Overview

Workbench is a directory of plain files — markdown skills, shell scripts, and a config file — that any AI coding agent can use. There is nothing to compile or install in the traditional sense. The "installation" is telling your agent tool where the files live, which is a one-line change to a steering doc.

The three skills (`skillify`, `session-extract`, `dream`) are ported almost verbatim from the Claude Code source. The Copilot hooks are new, written to implement the same trigger behaviour that Claude Code achieves via `registerPostSamplingHook` — but in plain shell, documented as a pattern others can follow.

---

## Directory Structure

```
workbench/
├── skills/
│   ├── skillify/
│   │   └── SKILL.md
│   ├── session-extract/
│   │   └── SKILL.md
│   └── dream/
│       └── SKILL.md
├── hooks/
│   └── copilot/                        ← reference implementation; rename for other tools
│       ├── hooks.README.md             ← explains the pattern + how to adapt
│       ├── hooks.json                  ← Copilot hook registration
│       ├── session-start.sh
│       ├── post-tool-use.sh
│       └── session-end.sh
├── memory/
│   └── MEMORY.md                       ← starts empty; grows with /dream
├── session-memory/                     ← per-session note files written by /session-extract
├── templates/
│   ├── session-memory-template.md      ← 10-section structure
│   ├── skill-template.md               ← blank SKILL.md for hand-authoring
│   └── steering-doc-template.md        ← MEMORY.md injection instruction, multi-tool guidance
├── .tmp/                               ← runtime state for hooks (tool counts, session IDs)
│   └── .gitkeep
└── config.yaml
```

---

## Architecture

### Data Flow

```
                    USER INVOKES                    AUTO (hooks)
                        │                               │
              ┌─────────┴──────────┐         ┌─────────┴──────────┐
              │                    │         │                     │
         /skillify           /dream      postToolUse           sessionEnd
              │                    │     (threshold)          (always)
              │                    │         │                     │
              ▼                    ▼         └────────┬────────────┘
    reads session-memory/    reads session-memory/    │
    reads MEMORY.md          reads memory/            ▼
              │                    │         /session-extract
              │                    ▼              │
              │            writes memory/         ▼
              ▼            writes MEMORY.md   writes session-memory/
    writes skills/                                   <slug>.md
    (user-chosen path)
                                    ▲
                            sessionStart hook
                                    │
                            writes .tmp/active-memory.md
                            (copy of MEMORY.md)
                                    │
                            copilot-instructions.md
                            instructs agent to read it
```

### Key Design Decisions

**Skills are self-contained markdown files.** Each skill carries its full prompt inline. There are no external dependencies, no imports, no runtime. Any agent that can read a file can use them.

**Session identity in hooks is derived from `cwd` + truncated timestamp.** Copilot hooks receive no session ID. `session-start.sh` writes a session key (`<cwd-slug>-<epoch-minutes>`) to `.tmp/current-session`. All subsequent hooks for that session read this key to name their state files consistently.

**MEMORY.md injection uses a temp file, not a direct path.** `copilot-instructions.md` cannot reference a path that changes content between sessions without being updated itself. Instead, `session-start.sh` copies the current `MEMORY.md` into `.tmp/active-memory.md`. The steering doc points at that stable path. If `MEMORY.md` doesn't exist, an empty file is written so the agent sees "no memory yet" rather than an error.

**The dream gate is pure shell.** Time gate: `stat -f %m` (macOS) / `stat -c %Y` (Linux) on `.tmp/dream-lock`. Session gate: `ls session-memory/ | wc -l` compared against a counter stored in `.tmp/session-count`. No database, no JSON parsing beyond `jq` for config reads.

**All thresholds come from `config.yaml`.** Hook scripts use `yq` (if available) or `grep`/`awk` to read values, with hardcoded fallbacks so `yq` is not a hard dependency.

---

## Components and Interfaces

### `skills/skillify/SKILL.md`

**Source:** Ported verbatim from `claude-code/src/skills/bundled/skillify.ts` — specifically the `SKILLIFY_PROMPT` constant (lines 22–156).

**Adaptations:**
- Path references changed: `.claude/skills/` → `.workbench/skills/` and `~/.claude/skills/` → `~/.workbench/skills/`; project-local option generalised to "your tool's skill directory (e.g. `.kilo/skills/`, `.claude/skills/`)"
- `AskUserQuestion` references softened to "use your tool's native question mechanism or structured prompts"
- `{{sessionMemory}}` placeholder: agent reads `~/.workbench/session-memory/` manually as part of Step 1 (no runtime injection needed — the agent can use `Read` or `Bash(cat)`)
- `USER_TYPE` gate removed entirely

**Structure:** 4-phase workflow — Analyse → Interview (4 rounds) → Write SKILL.md (with format spec) → Confirm and Save.

---

### `skills/session-extract/SKILL.md`

**Source:** Ported from `claude-code/src/services/sessionMemory/prompts.ts` — the `DEFAULT_SESSION_MEMORY_TEMPLATE` (lines 11–41) and `getDefaultUpdatePrompt()` (lines 43–100).

**Prompt structure:**

```
1. Read ~/.workbench/session-memory/<slug>.md if it exists (current notes)
2. Update every section where new information exists
3. Preserve all section headers and italic description lines exactly
4. Write the file back using Edit (parallel calls per section if updating)
5. Confirm path and one-line summary of changes
```

**Session slug derivation:** The skill instructs the agent to derive a slug from the current working directory and approximate session start time, e.g. `myproject-20260408-1430`. This is consistent with what `session-start.sh` writes to `.tmp/current-session`.

**10 sections** (verbatim from Claude Code's `DEFAULT_SESSION_MEMORY_TEMPLATE`):
Session Title, Current State, Task Specification, Files and Functions, Workflow, Errors & Corrections, Codebase and System Documentation, Learnings, Key Results, Worklog.

---

### `skills/dream/SKILL.md`

**Source:** Ported verbatim from `claude-code/src/services/autoDream/consolidationPrompt.ts` — the `buildConsolidationPrompt()` function body (lines 15–64).

**Adaptations:**
- `memoryRoot` hardcoded to `~/.workbench/memory/`
- `transcriptDir` changed to `~/.workbench/session-memory/` (structured `.md` files, not JSONL) — Phase 2 "Gather" instructions updated to reflect this: grep the `.md` files rather than JSONL transcripts
- `DIR_EXISTS_GUIDANCE` inlined as: "If the memory directory doesn't exist yet, create it with `mkdir -p` and start fresh."
- `ENTRYPOINT_NAME` = `MEMORY.md`, `MAX_ENTRYPOINT_LINES` = `500` — inlined as constants in the prompt text

**4-phase structure** (verbatim): Orient → Gather recent signal → Consolidate → Prune and index.

---

### `hooks/copilot/hooks.json`

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "type": "command", "bash": "./session-start.sh", "cwd": ".github/hooks/copilot", "timeoutSec": 15 }
    ],
    "postToolUse": [
      { "type": "command", "bash": "./post-tool-use.sh", "cwd": ".github/hooks/copilot", "timeoutSec": 10 }
    ],
    "sessionEnd": [
      { "type": "command", "bash": "./session-end.sh", "cwd": ".github/hooks/copilot", "timeoutSec": 30 }
    ]
  }
}
```

Note: `hooks.json` must live in `.github/hooks/` to be picked up by Copilot. The scripts reference workbench paths via `WORKBENCH_ROOT` env var (defaulting to `~/.workbench`).

---

### `hooks/copilot/session-start.sh`

**Trigger:** `sessionStart` — fires when a new or resumed session begins.

**Responsibilities:**
1. Derive session key: `slug=$(echo "$CWD" | tr '/' '-' | tr -cd '[:alnum:]-')`, append epoch-minutes
2. Write key to `$WORKBENCH_ROOT/.tmp/current-session`
3. Copy `$WORKBENCH_ROOT/memory/MEMORY.md` to `$WORKBENCH_ROOT/.tmp/active-memory.md` (write empty file if absent)
4. Check dream gate (time + session count) — if both thresholds exceeded, write `$WORKBENCH_ROOT/.tmp/dream-pending` flag file
5. Reset tool counter: `echo 0 > $WORKBENCH_ROOT/.tmp/tool-count-$SESSION_KEY`

**Output:** None (output ignored by Copilot for `sessionStart`).

---

### `hooks/copilot/post-tool-use.sh`

**Trigger:** `postToolUse` — fires after every tool execution.

**Responsibilities:**
1. Read session key from `.tmp/current-session`
2. Increment counter in `.tmp/tool-count-$SESSION_KEY`
3. Read threshold from `config.yaml` (default: 3)
4. If counter ≥ threshold: write `.tmp/extract-pending` flag; reset counter to 0

**Output:** None (output ignored by Copilot for `postToolUse`).

**Note:** The flag file mechanism relies on `copilot-instructions.md` instructing the agent to check for `.tmp/extract-pending` at the start of each turn and run `/session-extract` if present, then delete the flag. This is the only coupling between hook output and agent behaviour.

---

### `hooks/copilot/session-end.sh`

**Trigger:** `sessionEnd` — fires when session completes (reason: `complete`, `error`, `abort`, etc.).

**Responsibilities:**
1. Read session key from `.tmp/current-session`
2. Write `.tmp/extract-pending` flag (forces a final extract — but session is already ending, so this is informational/for next session pickup)
3. Increment `$WORKBENCH_ROOT/.tmp/session-count`
4. Clean up `.tmp/tool-count-$SESSION_KEY`

**Note:** Because `sessionEnd` fires after the session, the extraction itself cannot happen within that session. The flag written here is picked up by the *next* `sessionStart` to trigger an extraction pass on the previous session's notes. This is the correct behaviour — the extraction reviews what just happened.

---

### `hooks/copilot/hooks.README.md`

Documents:
- What each hook does in plain English
- The Copilot hook type each maps to (`sessionStart`, `postToolUse`, `sessionEnd`)
- How to adapt for another tool: "rename this folder to match your tool's hook convention, map each script to your tool's equivalent trigger, adjust the input parsing if your tool passes different JSON fields"
- The flag-file pattern for communicating between hooks and the agent (via steering doc)

---

### `templates/steering-doc-template.md`

The core injection instruction that goes into every tool's steering doc:

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

Includes per-tool placement guidance:
- **Copilot**: add to `.github/copilot-instructions.md`
- **Kilo / Claude Code**: add to `AGENTS.md` or `CLAUDE.md`, or add `~/.workbench/.tmp/active-memory.md` to `instructions[]` in config
- **Others**: any file the tool reads as a system prompt or persistent instruction

---

### `config.yaml`

```yaml
# Workbench configuration
# All paths support ~ expansion. Override WORKBENCH_ROOT env var to relocate entirely.

paths:
  memory_root: ~/.workbench/memory
  session_memory_root: ~/.workbench/session-memory
  tmp_root: ~/.workbench/.tmp

session_extract:
  min_tool_calls: 3          # trigger mid-session extraction after this many tool calls

dream:
  enabled: true
  min_sessions: 5            # sessions completed since last dream
  min_hours: 24              # hours since last dream

integrations:
  mempalace:
    enabled: auto            # auto = detect on PATH, true = force on, false = force off
```

---

## MemPalace Integration (Optional)

Workbench remains fully file-based and zero-dependency by default. MemPalace is treated as an optional enhancement layer that reduces token usage and improves retrieval quality when it is available, while leaving the base system unchanged when it is absent.

### Detection

All MemPalace touch points use the same shell guard:

```sh
MEMPALACE_ENABLED=false

if command -v mempalace >/dev/null 2>&1; then
  MEMPALACE_ENABLED=true
fi

# Then apply config override from integrations.mempalace.enabled
# auto  -> keep PATH-based detection
# true  -> force enabled
# false -> force disabled
```

This logic is factored into a shared shell helper sourced by the Copilot hooks so detection stays consistent across all entry points.

### Touch point 1 — `session-start.sh`

Without MemPalace, `session-start.sh` copies `~/.workbench/memory/MEMORY.md` into `~/.workbench/.tmp/active-memory.md`.

With MemPalace enabled, it instead runs:

```sh
mempalace wake-up > "$TMP_ROOT/active-memory.md"
```

If `mempalace wake-up` fails for any reason, the script falls back to the normal `MEMORY.md` copy behaviour. The steering doc remains unchanged because the agent still reads `~/.workbench/.tmp/active-memory.md` either way.

### Touch point 2 — `session-end.sh`

After writing the normal extraction handoff flag and incrementing the session counter, `session-end.sh` optionally indexes the session note into MemPalace:

```sh
SESSION_NOTE="$SESSION_MEMORY_ROOT/$SESSION_KEY.md"

if [ -f "$SESSION_NOTE" ]; then
  mempalace mine "$SESSION_NOTE" --mode convos >/dev/null 2>&1 || true
fi
```

This is best-effort only. Failures never block the hook or affect base workbench behaviour.

### Touch point 3 — `skills/dream/SKILL.md`

Phase 2 ("Gather recent signal") gets an optional retrieval path at the top:

```markdown
If you have access to MemPalace (CLI or MCP tools), prefer semantic retrieval
through it for finding relevant historical signal. Otherwise, use the direct
file-system workflow below against `~/.workbench/session-memory/*.md`.
```

The existing grep-based Phase 2 flow remains intact as the default fallback.

### Token-saving effect

| Scenario | Base workbench | Workbench + MemPalace |
|---|---|---|
| Session start context | Full `MEMORY.md` copied into `active-memory.md` | `mempalace wake-up` compact context written to `active-memory.md` |
| Dream gathering | Read / grep multiple `.md` session note files | Prefer semantic retrieval, fallback to grep |
| Session end | Schedule extraction only | Schedule extraction + optionally index note into MemPalace |

The integration is intentionally narrow: MemPalace enhances context loading and retrieval, but it does not replace workbench's flat-file memory model.

---

## Packaging and Developer Experience

Workbench is distributed as a Git repository whose contents are the actual product: markdown skills, shell hooks, templates, and config. To make adoption fast, the repository is paired with a primary installer script and a lightweight wrapper command.

### Packaging model

```
GitHub repository  ── source of truth
      │
      ├── install.sh        ← primary installer
      ├── bin/workbench     ← lightweight wrapper command
      └── workbench/ files  ← the actual product assets
```

This keeps the system transparent and hackable while still providing a fast installation path.

### Installation flows

Two installation flows are documented and supported:

1. **Recommended / safer default**

```sh
git clone <repo-url>
cd workbench
./install.sh
```

2. **Fast path**

```sh
curl -fsSL <install-script-url> | bash
```

The documentation presents the `git clone` flow first because it is easier to inspect and debug, while still keeping the one-liner available for convenience.

### `install.sh`

`install.sh` is the primary entry point for first-time setup. It is intentionally shell-first so it matches the rest of the project and avoids introducing a required runtime just for installation.

Responsibilities:

- Resolve `WORKBENCH_ROOT` (default: `~/.workbench`)
- Create required directories if missing
- Copy or sync the canonical files from the repo into the target root
- Ensure hook scripts are executable
- Offer optional Copilot hook install into a target repository
- Detect optional integrations (e.g. MemPalace) and report them without failing
- Print a concise post-install summary and the next recommended command (`workbench doctor`)

### `bin/workbench`

`bin/workbench` is a thin shell wrapper over the repository files. It is not a heavy CLI application; it simply orchestrates common workflows so users do not need to remember file paths.

Planned command surface:

```sh
workbench init
workbench install copilot [repo]
workbench doctor
workbench print steering-doc
workbench mempalace status
```

The wrapper should stay small and shell-based until there is a clear need for a richer implementation language.

### `workbench doctor`

`workbench doctor` verifies setup integrity and prints a human-readable health summary.

Checks include:

- workbench root exists
- required directories exist (`skills`, `hooks`, `templates`, `memory`, `.tmp`)
- key files exist (`config.yaml`, `templates/steering-doc-template.md`, `memory/MEMORY.md`)
- Copilot hook scripts are executable when installed
- optional tools (`jq`, `mempalace`) are either present or clearly marked optional
- steering-doc snippet can be printed and used

### `workbench print steering-doc`

This command prints the current steering-doc snippet directly to stdout. This avoids forcing users to browse template files manually and makes setup easier on work machines.

### `workbench install copilot`

This command installs or updates the reference Copilot hooks in a target repository by:

- creating `.github/hooks/` if needed
- copying `hooks.json`
- copying the `copilot/` hook scripts
- setting executable bits on `.sh` files
- printing the next manual step (`.github/copilot-instructions.md` snippet)

### DX principles

- **Repo-first**: the repository stays understandable and editable without the wrapper
- **Shell-first**: installation and wrapper stay close to the underlying system
- **No mandatory heavy runtime**: no Node/Python dependency required for core setup
- **Graceful optional integrations**: MemPalace and other extras are reported, not required
- **Fast verification**: every install ends with a clear health-check command

---

## Data Models

### Session Memory File

Path: `~/.workbench/session-memory/<cwd-slug>-<YYYYMMDD>-<HHMM>.md`

10 sections (verbatim from Claude Code `DEFAULT_SESSION_MEMORY_TEMPLATE`):
```
# Session Title
# Current State
# Task Specification
# Files and Functions
# Workflow
# Errors & Corrections
# Codebase and System Documentation
# Learnings
# Key Results
# Worklog
```

Each section header is followed by an italic description line (e.g. `_What is actively being worked on right now?_`) that acts as a permanent template instruction — the agent is instructed never to modify these lines, only the content beneath them.

### Memory Index File

Path: `~/.workbench/memory/MEMORY.md`

```markdown
# Memory
_Last consolidated: 2026-04-08_

## Topics
- [Git Workflow](git-workflow.md) — cherry-pick process, PR conventions, branch naming
- [Project: workbench](projects/workbench.md) — architecture, key files, patterns
- [Preferences](preferences.md) — coding style, preferred tools, response style
```

Kept under 500 lines / ~25KB. Each entry is one line ≤ 150 characters.

### Hook State Files (`.tmp/`)

| File | Written by | Read by | Content |
|---|---|---|---|
| `current-session` | `session-start.sh` | `post-tool-use.sh`, `session-end.sh` | session key string |
| `tool-count-<key>` | `post-tool-use.sh` | `post-tool-use.sh` | integer |
| `session-count` | `session-end.sh` | `session-start.sh` | integer |
| `dream-lock` | `session-start.sh` (on dream completion) | `session-start.sh` | epoch timestamp (mtime used) |
| `active-memory.md` | `session-start.sh` | agent (via steering doc) | copy of MEMORY.md |
| `extract-pending` | `post-tool-use.sh`, `session-end.sh` | agent (via steering doc) | empty flag file |
| `dream-pending` | `session-start.sh` | agent (via steering doc) | empty flag file |

When MemPalace is enabled, `active-memory.md` contains `mempalace wake-up` output instead of a direct copy of `MEMORY.md`. The filename and steering-doc contract do not change.

---

## Error Handling

| Scenario | Handling |
|---|---|
| `MEMORY.md` absent at session start | `session-start.sh` writes empty `active-memory.md` — agent sees "no memory yet", no error |
| `session-memory/` is empty when `/dream` runs | Skill prompt handles gracefully — Phase 2 finds nothing new, outputs "nothing to consolidate" |
| `config.yaml` missing or field absent | All scripts fall back to hardcoded defaults via shell `${VAR:-default}` syntax |
| `yq` not installed | Scripts fall back to `grep`/`awk` for config reading |
| `mempalace` not installed | Detection resolves false and the base workbench behaviour is used |
| `mempalace wake-up` fails | `session-start.sh` falls back to copying `MEMORY.md` into `active-memory.md` |
| `mempalace mine` fails | `session-end.sh` ignores the failure (`|| true`) and exits successfully |
| Hook script exits non-zero | Copilot logs the error but continues the session — hooks are best-effort |
| Session key file missing when `post-tool-use.sh` runs | Script exits 0 silently — session may have started before hooks were installed |
| Concurrent `session-end.sh` runs (race) | Counter increment uses `>>` append + `wc -l` pattern — monotonically correct, not atomic, acceptable for a non-critical counter |

---

## Testing Strategy

Since the deliverable is markdown and shell scripts rather than compiled code, testing is manual and exploratory:

- **Skills**: invoke each skill in Kilo or Claude Code with a sample session, verify the output matches the intended format
- **Hooks**: use the Copilot CLI hook debugging pattern (`echo '<json>' | ./session-start.sh`) to pipe test input and verify flag files are written/read correctly
- **Config fallbacks**: remove `config.yaml`, run hooks, verify defaults are used
- **MEMORY.md absent**: delete `memory/MEMORY.md`, start a new Copilot session, verify `active-memory.md` is written empty and no error appears
- **Dream gate**: manually set `dream-lock` mtime to >24h ago and `session-count` to ≥5, verify `dream-pending` is written on next session start
- **MemPalace absent**: ensure `mempalace` is not on `PATH`, run `session-start.sh`, verify the script falls back to normal `MEMORY.md` copy behaviour
- **MemPalace present**: run `session-start.sh` with `mempalace` available, verify `active-memory.md` contains wake-up output instead of the raw `MEMORY.md`
