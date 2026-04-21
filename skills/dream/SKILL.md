---
name: dream
description: Consolidate recent session notes into durable, well-organized memory files. Use periodically (every 5-10 sessions) to consolidate session notes into long-term memory, or when memory feels scattered.
---

# Dream: Memory Consolidation

You are performing a dream — a reflective pass over your memory files. Synthesize what you've learned recently into durable, well-organized memories so that future sessions can orient quickly.

Memory directory: `~/.workbench/memory/`
Session notes: `~/.workbench/session-memory/` (structured markdown files)

If the memory directory doesn't exist yet, create it with `mkdir -p ~/.workbench/memory/` and start fresh.

---

## Phase 1 — Orient

- `ls` the memory directory to see what already exists
- Read `MEMORY.md` to understand the current index
- Skim existing topic files so you improve them rather than creating duplicates

## Phase 2 — Gather recent signal

**Optional: If you have access to MemPalace** (CLI or MCP tools), prefer semantic retrieval for finding relevant historical signal. Use queries like:
- `mempalace search "recent errors" --limit 10`
- `mempalace search "project decisions" --limit 10`

**Otherwise, use file-system workflow:**

Look for new information worth persisting. Sources:

1. **Session notes** (`~/.workbench/session-memory/*.md`) — read recent files, grep for signal
2. **Existing memories that drifted** — facts that contradict something you see now

When searching session notes, use grep for narrow terms:
```bash
grep -rn "<term>" ~/.workbench/session-memory/ --include="*.md" | tail -50
```

Don't exhaustively read all notes. Look only for things you already suspect matter.

## Phase 3 — Consolidate

For each thing worth remembering, write or update a memory file at the top level of the memory directory.

Focus on:
- Merging new signal into existing topic files rather than creating near-duplicates
- Converting relative dates ("yesterday", "last week") to absolute dates so they remain interpretable after time passes
- Deleting contradicted facts — if recent work disproves an old memory, fix it at the source
- Organizing by topic: preferences, projects, workflows, learnings, etc.

## Phase 4 — Prune and index

Update `MEMORY.md` so it stays under 500 lines AND under ~25KB. It's an **index**, not a dump — each entry should be one line under ~150 characters: `- [Title](file.md) — one-line hook`. Never write memory content directly into it.

- Remove pointers to memories that are now stale, wrong, or superseded
- Demote verbose entries: if an index line is over ~200 chars, it's carrying content that belongs in the topic file — shorten the line, move the detail
- Add pointers to newly important memories
- Resolve contradictions — if two files disagree, fix the wrong one
- Update the "Last consolidated" timestamp at the top

---

Return a brief summary of what you consolidated, updated, or pruned. If nothing changed (memories are already tight), say so.
