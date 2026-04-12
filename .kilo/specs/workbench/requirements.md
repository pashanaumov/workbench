# Requirements

## Introduction

**Workbench** is a portable, tool-agnostic folder of agent enhancement primitives — skills, hooks, steering doc templates, memory files, and config — that a developer can install on any machine regardless of which AI coding tool they use.

The features are derived from analysis of the Claude Code source code (specifically the `skillify`, `sessionMemory`, and `autoDream` systems) and distilled into universal building blocks. There is no compilation step, no runtime dependency, and no tool-specific lock-in. Everything is markdown files and shell scripts.

The three core capabilities are:

1. **`/skillify`** — An interactive skill that captures the workflow performed in the current session as a reusable `SKILL.md` file, usable in any agent that supports custom prompts or skills.
2. **`/dream`** — A skill that consolidates structured session notes into durable, topic-based memory files and a `MEMORY.md` index, making the agent progressively more aware of the user's preferences and working patterns.
3. **`/session-extract`** — A skill that extracts structured notes from the current session into a per-session markdown file, preserving context across compactions and sessions.

Hooks (automation glue that fires these skills without user intervention) are provided as a **reference implementation for GitHub Copilot**, with comments throughout that document the pattern so users can adapt them for any other tool.

---

## Requirements

### Requirement 1 — `/skillify` Skill

**User Story:** As a developer, I want to run `/skillify` at the end of a productive agent session so that the workflow I just performed is captured as a reusable skill I can invoke in future sessions on any tool.

#### Acceptance Criteria

1. WHEN a user invokes `/skillify` (with an optional free-text description argument), THEN the skill SHALL analyse the session context and begin an interactive interview to capture the workflow.
2. WHEN the interview begins, THEN the skill SHALL suggest a skill name, description, and high-level steps derived from the session — the user SHALL NOT need to describe the process from scratch.
3. WHEN conducting the interview, THEN the skill SHALL ask all clarifying questions using the tool's native question mechanism (e.g. `AskUserQuestion` in Kilo/Claude Code, or structured prompts in Copilot), never via plain text.
4. WHEN the interview is complete, THEN the skill SHALL output the proposed `SKILL.md` content as a fenced code block for user review before writing anything to disk.
5. WHEN the user approves the proposed content, THEN the skill SHALL write the file to either a project-local path (e.g. `.kilo/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`) or a personal global path (e.g. `~/.workbench/skills/<name>/SKILL.md`), per the user's choice during the interview.
6. WHEN the skill is saved, THEN the skill SHALL confirm the exact path written and how to invoke it in the current tool.
7. IF the user provides a description argument, THEN that description SHALL be incorporated as context at the start of the interview.
8. IF session memory notes exist for the current session (`~/.workbench/session-memory/`), THEN the skill SHALL read and incorporate them into the analysis before the interview begins.

---

### Requirement 2 — `/session-extract` Skill

**User Story:** As a developer, I want structured notes about the current session to be written to disk so that context about what was done, discovered, and attempted is preserved across compactions, session restarts, and tool switches.

#### Acceptance Criteria

1. WHEN a user invokes `/session-extract`, THEN the skill SHALL analyse the current session's conversation history and write/update a structured markdown file at `~/.workbench/session-memory/<session-slug>.md`.
2. WHEN writing the file, THEN it SHALL contain the following sections: Session Title, Current State, Task Specification, Files and Functions, Workflow, Errors & Corrections, Codebase and System Documentation, Learnings, Key Results, Worklog.
3. WHEN the file already exists, THEN the skill SHALL update only sections where there is new information, preserving existing content that is still accurate.
4. WHEN the extraction is complete, THEN the skill SHALL confirm the path written and a one-line summary of what changed.
5. IF the session has not produced enough content to warrant notes, THEN the skill SHALL say so and exit without writing an empty file.
6. WHEN writing notes, THEN the skill SHALL NOT reference its own note-taking process or these instructions anywhere in the output file.

---

### Requirement 3 — `/dream` Skill

**User Story:** As a developer who uses AI coding tools regularly across multiple sessions, I want the agent to periodically consolidate what it has learned from my recent sessions into durable memory files so that future sessions begin with relevant context about my preferences, projects, and working patterns.

#### Acceptance Criteria

1. WHEN a user invokes `/dream`, THEN the skill SHALL read existing memory files in `~/.workbench/memory/` and recent session notes in `~/.workbench/session-memory/`, then synthesise new or updated topic-based memory files.
2. WHEN consolidating, THEN the skill SHALL update an index file at `~/.workbench/memory/MEMORY.md` with one-line entries linking to individual topic files.
3. WHEN consolidating, THEN the skill SHALL merge new signal into existing topic files rather than creating near-duplicates.
4. WHEN consolidating, THEN the skill SHALL convert relative date references ("yesterday", "last week") to absolute dates so entries remain interpretable over time.
5. WHEN consolidating, THEN the skill SHALL delete or correct facts in memory that are contradicted by more recent session notes.
6. WHEN the skill completes, THEN it SHALL output a brief summary of what was created, updated, or pruned.
7. WHEN the `MEMORY.md` index exists, THEN it SHALL be kept under 500 lines — entries that exceed ~150 characters SHALL be shortened, with detail moved to the topic file.
8. IF `~/.workbench/memory/` does not exist yet, THEN the skill SHALL create it and start fresh without error.

---

### Requirement 4 — MEMORY.md Auto-Injection (Steering Doc Pattern)

**User Story:** As a developer, I want the agent to automatically be aware of my consolidated memory at the start of every session without me having to manually include it each time.

#### Acceptance Criteria

1. WHEN `~/.workbench/memory/MEMORY.md` exists, THEN a steering doc template SHALL exist that instructs the agent to read this file at the start of every session.
2. WHEN the steering doc is in place, THEN the agent SHALL have access to consolidated memory without any per-session user action.
3. WHEN `~/.workbench/memory/MEMORY.md` does not exist yet, THEN the steering doc SHALL gracefully handle the absence (no error, no blocking).
4. The steering doc template SHALL include instructions for placing it correctly for at least two tools: GitHub Copilot (`.github/copilot-instructions.md`) and Kilo/Claude Code (`AGENTS.md` / `CLAUDE.md`).

---

### Requirement 5 — Copilot Hooks (Reference Implementation)

**User Story:** As a GitHub Copilot user, I want session extraction and memory injection to happen automatically without me having to remember to run `/session-extract` or `/dream` manually.

#### Acceptance Criteria

1. WHEN a Copilot agent session starts, THEN the `sessionStart` hook SHALL write the current content of `~/.workbench/memory/MEMORY.md` into a temp file (`~/.workbench/.tmp/active-memory.md`) so the agent can read it.
2. WHEN `~/.workbench/memory/MEMORY.md` does not exist, THEN the `sessionStart` hook SHALL write an empty placeholder so no file-not-found error occurs.
3. WHEN a tool call completes during a session (`postToolUse`), THEN the hook SHALL increment a per-session tool call counter stored in `~/.workbench/.tmp/`.
4. WHEN the tool call counter crosses the configured threshold (default: 3), THEN the `postToolUse` hook SHALL write a flag file that causes the agent to run `/session-extract` at its next turn.
5. WHEN a session ends (`sessionEnd`), THEN the hook SHALL always perform a final `/session-extract` pass regardless of whether the mid-session threshold was crossed.
6. WHEN the `sessionEnd` hook runs, THEN it SHALL increment a session completion counter in `~/.workbench/.tmp/session-count`.
7. WHEN the session count since last dream crosses the configured threshold (default: 5) AND the time since last dream crosses the configured threshold (default: 24 hours), THEN the `sessionEnd` hook SHALL write a flag that causes the agent to run `/dream` at the next session start.

**5.A — Reference Implementation Comments**

1. WHEN the hooks are written, THEN each script SHALL include a header comment block explaining: what this hook does, which Copilot hook type it maps to, and how to adapt it for another tool.
2. WHEN the `hooks.json` file is written, THEN it SHALL include a comment block (or adjacent `hooks.README.md`) explaining the folder naming convention and how to rename/adapt it for another tool's hook system.

---

### Requirement 6 — Config

**User Story:** As a developer, I want to configure thresholds and paths in one place so I can tune the system's behaviour without editing multiple script files.

#### Acceptance Criteria

1. WHEN the workbench is installed, THEN a `config.yaml` SHALL exist at the workbench root with all configurable values and their defaults.
2. The following values SHALL be configurable: `memory_root`, `session_memory_root`, `tmp_root`, `session_extract.min_tool_calls`, `dream.min_sessions`, `dream.min_hours`, `dream.enabled`.
3. WHEN a hook script reads a threshold, THEN it SHALL read from `config.yaml` rather than hardcoding values.
4. IF `config.yaml` is missing or a field is absent, THEN scripts SHALL fall back to hardcoded defaults without error.

---

### Requirement 7 — Templates

**User Story:** As a developer, I want ready-made templates for session memory files and skill files so I can hand-author or customise them without starting from scratch.

#### Acceptance Criteria

1. WHEN the workbench is installed, THEN a `templates/session-memory-template.md` SHALL exist containing the 10-section structure used by `/session-extract`.
2. WHEN the workbench is installed, THEN a `templates/skill-template.md` SHALL exist containing a blank SKILL.md with all frontmatter fields and section headers documented.
3. WHEN the workbench is installed, THEN a `templates/steering-doc-template.md` SHALL exist containing the MEMORY.md injection instruction and guidance for placing it in Copilot, Kilo, and Claude Code.

---

### Requirement 8 — MemPalace Integration (Optional)

**User Story:** As a developer who wants to minimise token usage across sessions, I want workbench to optionally use MemPalace for context loading and signal gathering so that my agent starts sessions with a compact wake-up context instead of the full `MEMORY.md`, and `/dream` can retrieve semantically relevant history without reading entire files.

#### Acceptance Criteria

1. IF MemPalace is not installed, THEN all workbench behaviour SHALL remain identical to the base system with no errors, no degraded experience, and no prompts to install it.
2. IF MemPalace is installed and available on `PATH`, THEN the Copilot `sessionStart` hook SHALL use `mempalace wake-up` output instead of copying the full `~/.workbench/memory/MEMORY.md` into `~/.workbench/.tmp/active-memory.md`.
3. WHEN `mempalace wake-up` is used, THEN its output SHALL be written to `~/.workbench/.tmp/active-memory.md` so the steering doc and agent continue to read the same stable path.
4. IF MemPalace is installed and enabled, THEN the Copilot `sessionEnd` hook SHALL attempt to index the current session note file into MemPalace after the extraction handoff has been scheduled.
5. IF MemPalace is installed and enabled, THEN `/dream` SHALL instruct the agent to prefer semantic retrieval through MemPalace when available, while preserving the existing grep-based fallback path when it is not.
6. WHEN workbench is installed, THEN `config.yaml` SHALL include an `integrations.mempalace.enabled` setting with the values `auto`, `true`, or `false`, where `auto` means detect MemPalace from `PATH`.
7. WHEN the Copilot hooks documentation is written, THEN it SHALL explain how optional MemPalace integration works, how to enable or disable it, and what token-saving tradeoff it provides.

---

### Requirement 9 — Packaging and Developer Experience

**User Story:** As a developer, I want workbench to be installable and verifiable in minutes so that I can start using it quickly without manually copying files, wiring paths, or debugging setup mistakes.

#### Acceptance Criteria

1. WHEN a user lands on the project for the first time, THEN the repository SHALL be the source of truth for all files, documentation, and installation flows.
2. WHEN a user installs workbench, THEN there SHALL be a primary shell installer (`install.sh`) that can set up the workbench root, create required directories, and guide the user through next steps.
3. WHEN installation instructions are documented, THEN both `git clone ... && ./install.sh` and `curl ... | bash` flows SHALL be supported, with the `git clone` flow presented first as the safer default.
4. WHEN a user wants command-line ergonomics, THEN a lightweight `workbench` wrapper command SHALL exist for common tasks without introducing a heavy runtime dependency.
5. WHEN a user runs `workbench doctor`, THEN the tool SHALL verify the presence of required directories, key files, executable hooks, steering-doc prerequisites, and optional integrations, then report a clear health summary.
6. WHEN a user runs `workbench print steering-doc`, THEN the tool SHALL print the current steering-doc snippet needed to wire workbench into an agent tool without requiring the user to open template files manually.
7. WHEN a user runs `workbench install copilot`, THEN the tool SHALL install or update the Copilot hook files into the target repository with executable permissions and provide clear follow-up instructions.
8. WHEN optional integrations such as MemPalace are absent, THEN the installer and wrapper SHALL report them as optional rather than as blocking failures.
9. WHEN installation completes, THEN the system SHALL print a concise summary of what was installed, what remains manual, and the recommended verification command.
