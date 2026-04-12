# Implementation Plan

---

## 1. Project skeleton

- [x] 1.1 Create directory structure
  - Create `skills/skillify/`, `skills/session-extract/`, `skills/dream/`
  - Create `hooks/copilot/`
  - Create `memory/`, `session-memory/`, `templates/`, `.tmp/`
  - Add `.gitkeep` to `memory/`, `session-memory/`, `.tmp/` so empty dirs are tracked
  - Add `session-memory/` and `.tmp/` to `.gitignore` (runtime files, not source)
  - _Requirements: all_

---

## 2. Config

- [x] 2.1 Write `config.yaml`
  - Include all configurable fields with defaults: `paths.memory_root`, `paths.session_memory_root`, `paths.tmp_root`, `session_extract.min_tool_calls`, `dream.enabled`, `dream.min_sessions`, `dream.min_hours`
  - Add inline comments on every field explaining what it controls
  - Add header comment: "Override WORKBENCH_ROOT env var to relocate the entire workbench"
  - _Requirements: 6.1, 6.2_

---

## 3. Templates

- [x] 3.1 Write `templates/session-memory-template.md`
  - Port `DEFAULT_SESSION_MEMORY_TEMPLATE` verbatim from `claude-code/src/services/sessionMemory/prompts.ts` lines 11–41
  - All 10 sections with italic description lines intact
  - Add a header comment explaining: "This template is used by /session-extract. Copy to ~/.workbench/session-memory/<slug>.md to pre-seed a session."
  - _Requirements: 7.1_

- [x] 3.2 Write `templates/skill-template.md`
  - Blank SKILL.md with all frontmatter fields (`name`, `description`, `allowed-tools`, `when_to_use`, `argument-hint`, `arguments`, `context`) documented with inline comments
  - Body sections: `# Title`, `## Inputs`, `## Goal`, `## Steps` — each with a brief comment explaining what to write
  - _Requirements: 7.2_

- [x] 3.3 Write `templates/steering-doc-template.md`
  - The three-instruction block from the design (`read active-memory.md`, check `extract-pending`, check `dream-pending`)
  - Per-tool placement guidance sections for: GitHub Copilot, Kilo Code, Claude Code, and a generic "Other tools" section
  - Note that for Kilo/Claude Code, users can alternatively add `~/.workbench/.tmp/active-memory.md` to `instructions[]` in their config file instead
  - _Requirements: 4.1, 4.3, 4.4, 7.3_

---

## 4. Skills

- [x] 4.1 Write `skills/skillify/SKILL.md`
  - SKILL.md frontmatter: `name: skillify`, `description`, `allowed-tools: [Read, Write, Edit, Glob, Grep, Bash(mkdir:*)]`, `argument-hint: "[description of process to capture]"`, `when_to_use`
  - Body: port `SKILLIFY_PROMPT` verbatim from `claude-code/src/skills/bundled/skillify.ts` lines 22–156
  - Apply adaptations: replace `.claude/skills/` with tool-agnostic phrasing; replace `~/.claude/skills/` with `~/.workbench/skills/`; remove `AskUserQuestion` hardcoding — replace with "use your tool's native question/confirmation mechanism"; add Step 1 instruction to check `~/.workbench/session-memory/` for existing notes using `Read` or `Bash(ls)`
  - Remove the `USER_TYPE !== 'ant'` guard (it is not present in the prompt itself, only in the registration wrapper — nothing to remove in the markdown)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_

- [x] 4.2 Write `skills/session-extract/SKILL.md`
  - SKILL.md frontmatter: `name: session-extract`, `description`, `allowed-tools: [Read, Write, Edit, Bash(mkdir:*)]`, `when_to_use`
  - Body prompt structure (5 sections):
    1. **Derive slug**: instruct agent to build `<cwd-basename>-<YYYYMMDD>-<HHMM>` from cwd and approximate session start time; read `.tmp/current-session` if it exists and use that key instead
    2. **Read existing notes**: read `~/.workbench/session-memory/<slug>.md` if present; load `templates/session-memory-template.md` as the structure if not
    3. **Update instructions**: port `getDefaultUpdatePrompt()` from `claude-code/src/services/sessionMemory/prompts.ts` lines 43–100 — replace `{{notesPath}}` and `{{currentNotes}}` with the resolved values; keep all CRITICAL RULES verbatim; replace `Edit tool` references with generic "write/edit the file"
    4. **Section size guidance**: port `generateSectionReminders()` logic as static text: remind agent to keep each section under ~2000 tokens and the total file under ~12000 tokens; condense by cycling out older detail if over budget
    5. **Confirm**: output the path written and a one-line summary of changes; if session has no substantive content, say so and exit without writing
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 4.3 Write `skills/dream/SKILL.md`
  - SKILL.md frontmatter: `name: dream`, `description`, `allowed-tools: [Read, Write, Edit, Glob, Bash(ls:*), Bash(grep:*), Bash(find:*), Bash(mkdir:*)]`, `when_to_use`
  - Body: port `buildConsolidationPrompt()` output verbatim from `claude-code/src/services/autoDream/consolidationPrompt.ts` lines 15–64
  - Apply adaptations:
    - Replace `${memoryRoot}` with `~/.workbench/memory/`
    - Replace transcript grep instructions (`grep ... --include="*.jsonl"`) with `grep ... --include="*.md"` pointing at `~/.workbench/session-memory/`
    - Replace `${DIR_EXISTS_GUIDANCE}` with inline text: "If the memory directory doesn't exist yet, create it with `mkdir -p ~/.workbench/memory/` and start fresh."
    - Replace `${ENTRYPOINT_NAME}` with `MEMORY.md` throughout
    - Replace `${MAX_ENTRYPOINT_LINES}` with `500`
    - Update Phase 2 source list: remove "Daily logs" and "JSONL transcripts" bullet; replace with "Session notes (`~/.workbench/session-memory/*.md`) — read recent files, grep for signal"
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 4.4 Write `memory/MEMORY.md`
  - Stub file with header `# Memory` and `_No consolidations yet. Run /dream after a few sessions._`
  - This is the live file that grows — committed as an empty seed
  - _Requirements: 3.8, 4.1_

---

## 5. Copilot hooks

- [x] 5.1 Write `hooks/copilot/hooks.README.md`
  - Section 1: "What this folder is" — reference implementation of the workbench hook pattern for GitHub Copilot
  - Section 2: "How to install" — copy `hooks.json` and scripts to `.github/hooks/copilot/` in your repo; make scripts executable (`chmod +x *.sh`)
  - Section 3: "How the hooks work" — plain-English description of each hook's responsibility and which Copilot hook type it maps to
  - Section 4: "Adapting for another tool" — rename this folder; map each script to your tool's equivalent trigger; adjust the JSON input parsing if your tool passes different fields; the flag-file pattern (write a file, steering doc tells agent to check it) is the universal communication mechanism
  - Section 5: "The flag-file pattern explained" — why hooks can't inject into the agent directly and how the steering doc bridges the gap
  - _Requirements: 5.A.1, 5.A.2_

- [x] 5.2 Write `hooks/copilot/hooks.json`
  - Register three hooks: `sessionStart` → `session-start.sh`, `postToolUse` → `post-tool-use.sh`, `sessionEnd` → `session-end.sh`
  - All with `cwd` set to the hooks directory, `timeoutSec`: 15 for start, 10 for postToolUse, 30 for end
  - Add adjacent comment file or JSON comment block (via `_comment` key) noting: "This file must be placed in .github/hooks/ on the default branch to be used by Copilot cloud agent"
  - _Requirements: 5_

- [x] 5.3 Write `hooks/copilot/session-start.sh`
  - Header comment block: hook purpose, Copilot trigger type, adaptation notes
  - Read JSON input from stdin (`INPUT=$(cat)`); parse `cwd` and `timestamp` with `jq`
  - Set `WORKBENCH_ROOT` from env var, default `~/.workbench`; read config fallbacks
  - Derive session key from cwd basename + epoch-minutes; write to `.tmp/current-session`
  - Copy `MEMORY.md` to `.tmp/active-memory.md`; write empty file if absent
  - Reset tool counter to 0
  - Dream gate check: read `dream-lock` mtime (portable: try `stat -f %m` then `stat -c %Y`); compare against `now - (min_hours * 3600)`; read `session-count`; if both thresholds met write `.tmp/dream-pending`
  - Check for `extract-pending` from previous session — if present, leave it (steering doc handles it at turn start)
  - Exit 0
  - _Requirements: 5.1, 5.2, 5.7_

- [x] 5.4 Write `hooks/copilot/post-tool-use.sh`
  - Header comment block: hook purpose, Copilot trigger type, adaptation notes
  - Read JSON input from stdin; parse `toolName` and `toolResult.resultType` with `jq`
  - Read session key from `.tmp/current-session`; if absent exit 0 silently
  - Increment counter file `.tmp/tool-count-<key>` using append + `wc -l`
  - Read `session_extract.min_tool_calls` from `config.yaml` (default 3)
  - If count ≥ threshold: write `.tmp/extract-pending`; reset counter to 0
  - Exit 0
  - _Requirements: 5.3, 5.4_

- [x] 5.5 Write `hooks/copilot/session-end.sh`
  - Header comment block: hook purpose, Copilot trigger type, adaptation notes, note about why extraction happens next session not this one
  - Read JSON input from stdin; parse `reason` with `jq`
  - Write `.tmp/extract-pending` (unconditionally — final extraction pass for this session, picked up next sessionStart)
  - Increment `session-count` using append + `wc -l`
  - Clean up `.tmp/tool-count-<key>`
  - Exit 0
  - _Requirements: 5.5, 5.6, 5.7_

---

## 6. Final wiring

- [x] 6.1 Write root `README.md`
  - What workbench is (one paragraph)
  - Directory map with one-line description per folder
  - Quick-start: 3 steps — clone/copy to `~/.workbench`, add steering doc snippet to your tool, optionally install Copilot hooks
  - Links to `templates/steering-doc-template.md` and `hooks/copilot/hooks.README.md` for detail
  - _Requirements: all_

---

## 7. MemPalace integration (optional)

- [x] 7.1 Add MemPalace settings to `config.yaml`
  - Add `integrations.mempalace.enabled: auto`
  - Document allowed values inline: `auto`, `true`, `false`
  - Explain that `auto` means detect `mempalace` from `PATH`
  - _Requirements: 8.6_

- [x] 7.2 Create `hooks/copilot/lib/detect.sh`
  - Export shared shell helpers for optional integration detection
  - Implement `mempalace_enabled()` using both `command -v mempalace` and `config.yaml` override semantics
  - Keep it dependency-light: use shell + existing config parsing strategy from the other hooks
  - _Requirements: 8.1, 8.6_

- [x] 7.3 Update `hooks/copilot/session-start.sh` for optional MemPalace wake-up
  - Source `lib/detect.sh`
  - If MemPalace is enabled: run `mempalace wake-up > "$TMP_ROOT/active-memory.md"`
  - If wake-up fails or MemPalace is disabled: fall back to the existing `MEMORY.md` copy behaviour
  - Keep the steering-doc contract unchanged — always write to `active-memory.md`
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 7.4 Update `hooks/copilot/session-end.sh` for optional MemPalace indexing
  - Source `lib/detect.sh`
  - After normal workbench end-of-session bookkeeping, attempt `mempalace mine` on the current session note file when enabled
  - Wrap the indexing call in `|| true` so failure never breaks the hook
  - _Requirements: 8.1, 8.4_

- [x] 7.5 Update `skills/dream/SKILL.md` with optional MemPalace retrieval path
  - Add a short instruction at the top of Phase 2 telling the agent to prefer MemPalace semantic retrieval when available
  - Preserve the existing grep/file-system workflow as the default fallback path
  - _Requirements: 8.5_

- [x] 7.6 Update `hooks/copilot/hooks.README.md` with MemPalace integration guidance
  - Explain what MemPalace adds, why it is optional, and the token-saving tradeoff
  - Document the three touch points: session start wake-up, session end indexing, dream retrieval
  - Document how to force-disable it via `integrations.mempalace.enabled: false`
  - _Requirements: 8.7_

---

## 8. Packaging and developer experience

- [x] 8.1 Write `install.sh`
  - Resolve `WORKBENCH_ROOT` with default `~/.workbench`
  - Create required directories if missing
  - Copy or sync the canonical repo files into the target root
  - Ensure `.sh` hook files are executable
  - Print concise post-install summary and recommend `workbench doctor`
  - _Requirements: 9.2, 9.9_

- [x] 8.2 Create `bin/workbench`
  - Implement a lightweight shell wrapper command
  - Support subcommands: `init`, `install copilot`, `doctor`, `print steering-doc`, `mempalace status`
  - Keep the wrapper thin and file-oriented rather than building a heavy standalone CLI
  - _Requirements: 9.4_

- [x] 8.3 Implement `workbench doctor`
  - Verify required directories and key files exist
  - Verify installed Copilot hook scripts are executable when present
  - Verify optional dependencies (`jq`, `mempalace`) and report them as optional
  - Print a human-readable health summary with pass/warn/fail style output
  - _Requirements: 9.5, 9.8, 9.9_

- [x] 8.4 Implement `workbench print steering-doc`
  - Print the current steering-doc snippet from `templates/steering-doc-template.md`
  - Avoid requiring the user to manually open template files
  - _Requirements: 9.6_

- [x] 8.5 Implement `workbench install copilot`
  - Accept a target repository path (default current directory)
  - Create `.github/hooks/` if needed
  - Copy `hooks.json` and the Copilot hook scripts into the correct location
  - Ensure installed scripts are executable
  - Print follow-up instructions for `.github/copilot-instructions.md`
  - _Requirements: 9.7, 9.9_

- [x] 8.6 Update root `README.md` for installation flows
  - Document `git clone ... && ./install.sh` first as the recommended path
  - Document `curl ... | bash` as the fast path second
  - Document how the wrapper command is exposed and how to run `workbench doctor`
  - _Requirements: 9.1, 9.3_
