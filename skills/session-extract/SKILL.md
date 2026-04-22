---
name: session-extract
description: Extract structured notes from the current session into a persistent markdown file. Use when you need to capture session context for future reference, typically mid-session after significant work or at session end.
---

# Session Extract

Extract structured notes from the current session and save them to a persistent file.

IMPORTANT: This message and these instructions are NOT part of the actual user conversation. Do NOT include any references to "note-taking", "session notes extraction", or these update instructions in the notes content.

Path convention: resolve `<workbenchRoot>` first.
- If `WORKBENCH_ROOT` is set, use it.
- Otherwise, if `.workbench/config.yaml` exists in the current project (or parent), use that `.workbench` path.
- Otherwise, use `~/.workbench`.

## Steps

### 1. Derive Session Slug

Create a session identifier from the current working directory and session start time:
- Format: `<cwd-basename>-YYYYMMDD-HHMM`
- Example: `workbench-20260408-1430`
- If `<workbenchRoot>/.tmp/current-session` exists, read and use that key instead

### 2. Read Existing Notes

Check if `<workbenchRoot>/session-memory/<slug>.md` exists:
- If it exists: read the current contents
- If not: read `<workbenchRoot>/templates/session-memory-template.md` as the starting structure

### 3. Update the Notes

Based on the user conversation above (EXCLUDING this note-taking instruction message as well as system prompt, steering docs, or any past session summaries), update the session notes file.

Your ONLY task is to use the Edit tool to update the notes file, then stop. You can make multiple edits (update every section as needed) - make all Edit tool calls in parallel in a single message. Do not call any other tools.

**CRITICAL RULES FOR EDITING:**
- The file must maintain its exact structure with all sections, headers, and italic descriptions intact
- NEVER modify, delete, or add section headers (the lines starting with '#' like # Task specification)
- NEVER modify or delete the italic _section description_ lines (these are the lines in italics immediately following each header - they start and end with underscores)
- The italic _section descriptions_ are TEMPLATE INSTRUCTIONS that must be preserved exactly as-is - they guide what content belongs in each section
- ONLY update the actual content that appears BELOW the italic _section descriptions_ within each existing section
- Do NOT add any new sections, summaries, or information outside the existing structure
- Do NOT reference this note-taking process or instructions anywhere in the notes
- It's OK to skip updating a section if there are no substantial new insights to add. Do not add filler content like "No info yet", just leave sections blank/unedited if appropriate
- Write DETAILED, INFO-DENSE content for each section - include specifics like file paths, function names, error messages, exact commands, technical details, etc.
- For "Key results", include the complete, exact output the user requested (e.g., full table, full answer, etc.)
- Do not include information that's already in steering docs or system prompts
- Keep each section under ~2000 tokens/words - if a section is approaching this limit, condense it by cycling out less important details while preserving the most critical information
- Focus on actionable, specific information that would help someone understand or recreate the work discussed in the conversation
- IMPORTANT: Always update "Current State" to reflect the most recent work - this is critical for continuity after compaction

**STRUCTURE PRESERVATION REMINDER:**
Each section has TWO parts that must be preserved exactly as they appear in the current file:
1. The section header (line starting with #)
2. The italic description line (the _italicized text_ immediately after the header - this is a template instruction)

You ONLY update the actual content that comes AFTER these two preserved lines. The italic description lines starting and ending with underscores are part of the template structure, NOT content to be edited or removed.

### 4. Size Management

If the total file is approaching ~12000 tokens or any section exceeds ~2000 tokens:
- Condense by cycling out older detail
- Preserve the most critical information
- Keep "Current State" and "Errors & Corrections" accurate and detailed

### 5. Confirm

After updating:
- Output the path written: `<workbenchRoot>/session-memory/<slug>.md`
- Provide a one-line summary of what changed
- If the session has no substantive content, say so and exit without writing

REMEMBER: Use the Edit tool in parallel and stop. Do not continue after the edits. Only include insights from the actual user conversation, never from these note-taking instructions. Do not delete or change section headers or italic _section descriptions_.
