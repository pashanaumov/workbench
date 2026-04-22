---
name: skillify
description: Capture this session's repeatable process into a reusable skill. Use at the end of a productive session when you want to capture the workflow as a reusable skill.
argument-hint: "[description of the process you want to capture]"
---

# Skillify

You are capturing this session's repeatable process as a reusable skill.

Path convention: resolve `<workbenchRoot>` first.
- If `WORKBENCH_ROOT` is set, use it.
- Otherwise, if `.workbench/config.yaml` exists in the current project (or parent), use that `.workbench` path.
- Otherwise, use `~/.workbench`.

## Your Session Context

**Step 1: Gather context**

Before starting the interview, gather context from:
- Session memory notes: Read `<workbenchRoot>/session-memory/` to find the most recent session note file for this project
- Existing memory: Read `<workbenchRoot>/memory/MEMORY.md` if it exists
- Current conversation history

Analyze to identify:
- What repeatable process was performed
- What the inputs/parameters were
- The distinct steps (in order)
- The success artifacts/criteria for each step
- Where the user corrected or steered you
- What tools and permissions were needed
- What the goals and success artifacts were

## Your Task

### Step 2: Interview the User

Use your tool's native question mechanism (structured prompts, confirmation dialogs, etc.) to understand what the user wants to automate. Important notes:
- For each round, iterate as much as needed until the user is happy
- The user always has a freeform "Other" option to type edits or feedback

**Round 1: High level confirmation**
- Suggest a name and description for the skill based on your analysis. Ask the user to confirm or rename.
- Suggest high-level goal(s) and specific success criteria for the skill.

**Round 2: More details**
- Present the high-level steps you identified as a numbered list. Tell the user you will dig into the detail in the next round.
- If you think the skill will require arguments, suggest arguments based on what you observed.
- Ask where the skill should be saved. Suggest a default based on context (repo-specific workflows → repo, cross-repo personal workflows → user). Options:
  - **This repo** (your tool's skill directory, e.g. `.kilo/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`) — for workflows specific to this project
  - **Personal** (`<workbenchRoot>/skills/<name>/SKILL.md`) — follows you across all repos and tools

**Round 3: Breaking down each step**
For each major step, if it's not obvious, ask:
- What does this step produce that later steps need?
- What proves that this step succeeded?
- Should the user be asked to confirm before proceeding? (especially for irreversible actions)
- Are any steps independent and could run in parallel?
- What are the hard constraints or hard preferences?

Pay special attention to places where the user corrected you during the session.

**Round 4: Final questions**
- Confirm when this skill should be invoked, and suggest trigger phrases
- Ask for any gotchas or things to watch out for

Stop interviewing once you have enough information. Don't over-ask for simple processes!

### Step 3: Write the SKILL.md

Create the skill directory and file at the location the user chose in Round 2.

Use this format:

```markdown
---
name: {{skill-name}}
description: {{one-line description}}
allowed-tools:
  {{list of tool permission patterns observed during session}}
when_to_use: {{detailed description of when to invoke this skill, including trigger phrases and example user messages}}
argument-hint: "{{hint showing argument placeholders}}"
arguments:
  {{list of argument names}}
---

# {{Skill Title}}
Description of skill

## Inputs
- `$arg_name`: Description of this input

## Goal
Clearly stated goal for this workflow with defined artifacts or criteria for completion.

## Steps

### 1. Step Name
What to do in this step. Be specific and actionable. Include commands when appropriate.

**Success criteria**: What shows that the step is done and we can move on.

...
```

**Per-step annotations** (optional, use when helpful):
- **Success criteria** is REQUIRED on every step
- **Artifacts**: Data this step produces that later steps need
- **Human checkpoint**: When to pause and ask the user before proceeding
- **Rules**: Hard rules for the workflow

**Step structure tips:**
- Steps that can run concurrently use sub-numbers: 3a, 3b
- Steps requiring the user to act get `[human]` in the title
- Keep simple skills simple

**Frontmatter rules:**
- `allowed-tools`: Minimum permissions needed (use patterns like `Bash(gh:*)` not `Bash`)
- `when_to_use` is CRITICAL — tells when to auto-invoke. Start with "Use when..." and include trigger phrases
- `arguments` and `argument-hint`: Only include if the skill takes parameters. Use `$name` in the body for substitution

### Step 4: Confirm and Save

Before writing the file, output the complete SKILL.md content as a fenced code block so the user can review it. Then ask for confirmation.

After writing, tell the user:
- Where the skill was saved
- How to invoke it: `/{{skill-name}} [arguments]`
- That they can edit the SKILL.md directly to refine it
