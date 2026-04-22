---
name: workbench
description: Configure workbench settings and integrations. Use when user wants to configure workbench, toggle features, enable/disable the codebase indexer MCP, or check status.
argument-hint: "[command] [args...]"
---

# Workbench Configuration

Interactive configuration and status management for workbench.

## Commands

### `setup`
Add workbench steering doc to the current AI tool's configuration file.

**Steps:**
1. Detect the current AI tool by checking for config files:
   - `.github/copilot-instructions.md` → GitHub Copilot
   - `AGENTS.md` → Kiro CLI / Claude Code
   - `.cursorrules` → Cursor
   - `.windsurfrules` → Windsurf
2. Read the steering doc template from `~/.workbench/templates/steering-doc-template.md`
3. Extract the relevant section for the detected tool
4. Check if steering doc is already present in the config file
5. If not present, append it to the config file
6. If file doesn't exist, create it with the steering doc
7. Confirm what was added and where

**Example output:**
```
✓ Detected GitHub Copilot (.github/copilot-instructions.md)
✓ Added workbench steering doc to .github/copilot-instructions.md

Next: Restart your AI tool to load the new instructions
```

### `status`
Show current workbench configuration and integration status.

**Steps:**
1. Read `~/.workbench/config.yaml`
2. Check if mempalace is installed: `command -v mempalace`
3. Display:
   - Workbench root path
   - Current mode (global/local/hybrid)
   - Memory paths
   - Session extract settings
   - Dream settings
   - MemPalace status (installed/enabled/disabled)
   - Active integrations

### `mode <global|local|hybrid>`
Switch between global, local, or hybrid mode.

**Steps:**
1. Read `~/.workbench/config.yaml`
2. Update `mode` to the specified value
3. Write back to config file
4. Explain what the mode means:
   - **global**: Only use `~/.workbench/` (skills, memory, config)
   - **local**: Only use `.workbench/` in project root
   - **hybrid**: Check both, project-local overrides global
5. Confirm the change

### `mempalace on|off`
Enable or disable MemPalace integration.

**Steps:**
1. Read `~/.workbench/config.yaml`
2. Update `integrations.mempalace.enabled` to `true` or `false`
3. Write back to config file
4. If enabling and mempalace not installed, show installation instructions:
   ```
   MemPalace not found. Install with:
   npm install -g @mempalace/cli
   # or
   brew install mempalace
   ```
5. Confirm the change

### `dream on|off`
Enable or disable automatic dream consolidation.

**Steps:**
1. Read `~/.workbench/config.yaml`
2. Update `dream.enabled` to `true` or `false`
3. Write back to config file
4. Confirm the change

### `config`
Show full configuration file.

**Steps:**
1. Read and display `~/.workbench/config.yaml`

### `config set <key> <value>`
Update a configuration value.

**Steps:**
1. Read `~/.workbench/config.yaml`
2. Update the specified key (supports dot notation: `dream.min_sessions`)
3. Write back to config file
4. Confirm the change

### `gh hooks init`

Deploy Copilot CLI hooks to the current project's `.github/hooks/` directory.

Hooks can only be loaded per-project (Copilot CLI reads from `.github/hooks/` in the CWD).
Skills can be global; hooks cannot. This command bridges that gap.

**Steps:**
1. Verify `~/.workbench/hooks/copilot/` exists as the source
2. Check if `.github/hooks/copilot/` already exists — if so, confirm with the user before overwriting
3. Run:
   ```bash
   mkdir -p .github/hooks
   cp -r ~/.workbench/hooks/copilot .github/hooks/
   chmod +x .github/hooks/copilot/*.sh
   ```
4. Confirm success and show next steps:
   - **CLI**: hooks are active immediately
   - **Cloud agent**: commit `.github/hooks/` to the default branch

**Example output:**
```
✓ Hooks deployed to .github/hooks/copilot/
  → sessionStart, postToolUse, sessionEnd

For Copilot CLI: hooks are active immediately.
For cloud agent: commit .github/hooks/ to your default branch.
```

### `gh hooks status`

Check whether hooks are deployed in the current project.

**Steps:**
1. Check if `.github/hooks/copilot/hooks.json` exists
2. Check if the shell scripts are executable (`-x`)
3. Report status for each expected file: `hooks.json`, `session-start.sh`, `post-tool-use.sh`, `session-end.sh`

**Example output:**
```
Hooks: .github/hooks/copilot/
  ✓ hooks.json
  ✓ session-start.sh  (executable)
  ✗ post-tool-use.sh  (not found)

Run /workbench gh hooks init to deploy.
```

### `indexer enable`

Register the workbench-indexer MCP server with Claude Code so it is auto-started on every session.

**Steps:**

1. **Find the repo root.** Check in this order:
   - Does `packages/mcp/src/index.ts` exist in the current directory? → use `pwd`
   - Does `~/.workbench/indexer.json` exist and contain a valid `repoRoot`? → use that
   - Try common locations: `~/workbench`, `~/projects/workbench`, `~/code/workbench`, `~/Desktop/workbench`
   - If none found, ask the user: "Where is the workbench repo cloned? (full path)"

2. **Verify** `<repoRoot>/packages/mcp/src/index.ts` and `<repoRoot>/packages/core/loader.mjs` exist. If not, tell the user the path seems wrong.

3. **Generate `~/.workbench/bin/wb-mcp`** — a small wrapper script:
   ```bash
   #!/usr/bin/env bash
   # Generated by: /workbench indexer enable
   # Workbench indexer MCP server launcher
   exec node \
     --experimental-strip-types \
     --experimental-loader "<repoRoot>/packages/core/loader.mjs" \
     "<repoRoot>/packages/mcp/src/index.ts"
   ```
   Then `chmod +x ~/.workbench/bin/wb-mcp`.

4. **Save repo root** to `~/.workbench/indexer.json`:
   ```json
   { "repoRoot": "<repoRoot>" }
   ```

5. **Edit `~/.claude/.mcp.json`:**
   - If file does not exist, create it: `{ "mcpServers": {} }`
   - Add or overwrite the `workbench-indexer` key:
   ```json
   "workbench-indexer": {
     "command": "wb-mcp",
     "disabled": false,
     "autoApprove": ["search_code", "get_indexing_status"]
   }
   ```
   - Write the file back (preserve all other entries).

6. **Confirm:**
   ```
   ✓ wb-mcp wrapper written to ~/.workbench/bin/wb-mcp
   ✓ workbench-indexer added to ~/.claude/.mcp.json

   Next steps:
     1. Run `wb index` in your project (downloads model + grammars on first run, ~400 MB)
     2. Restart Claude Code to load the new MCP server
     3. In your project, ask Claude: "index this codebase" to build the index
   ```

---

### `indexer disable`

Disable the workbench-indexer MCP server without removing its configuration.

**Steps:**

1. Read `~/.claude/.mcp.json`. If missing or `workbench-indexer` not present, say "Indexer is not configured — run `/workbench indexer enable` first."
2. Set `mcpServers.workbench-indexer.disabled = true`.
3. Write the file back.
4. Confirm:
   ```
   ✓ workbench-indexer disabled in ~/.claude/.mcp.json
   Restart Claude Code to apply.
   Run `/workbench indexer enable` to re-enable.
   ```

---

### `indexer status`

Show the current state of the indexer: MCP registration, model setup, and index for the current project.

**Steps:**

1. **MCP registration** — read `~/.claude/.mcp.json`:
   - Not present → `✗ Not registered`
   - Present, `disabled: true` → `⚠ Registered but disabled`
   - Present, enabled → `✓ Registered and active`

2. **Model setup** — check `~/.workbench/grammars/tree-sitter-python.wasm` exists AND `~/.workbench/models/jinaai` (or any subdirectory) has `.onnx` files:
   - Missing → `✗ Setup not done — run: wb index (triggers auto-setup)`
   - Present → `✓ Model and grammars ready`

3. **Project index** — compute the project hash from cwd:
   - Hash = first 12 chars of `sha256(cwd)` (hex)
   - Check `~/.workbench/<hash>/stats.json`
   - Missing → `○ No index for this project yet`
   - Present → parse and show:
     ```
     ✓ Index: ~/.workbench/<hash>/
       Last indexed: <lastIndexedAt as human date>
       Chunks: <chunkCount>
     ```

4. **Print summary** — example output:
   ```
   Workbench Indexer Status
   ═════════════════════════
   MCP server:   ✓ Registered and active
   Model/grammars: ✓ Ready
   Project index:  ✓ 847 chunks (last indexed: 2 hours ago)

   Project:  /Users/you/your-project
   Index at: ~/.workbench/a3f9b21c4d8e/
   ```

---

## Usage Examples

```
/workbench setup
/workbench status
/workbench mode hybrid
/workbench mempalace on
/workbench dream off
/workbench config
/workbench config set dream.min_sessions 3
/workbench gh hooks init
/workbench gh hooks status
/workbench indexer enable
/workbench indexer disable
/workbench indexer status
```

## Notes

- All config changes are immediate
- Invalid keys will show an error
- Use `workbench doctor` CLI command for health checks
- `indexer enable` is safe to re-run — it overwrites only the `workbench-indexer` entry in `.mcp.json`
- If you move the workbench repo, re-run `/workbench indexer enable` from the new location to regenerate the `wb-mcp` wrapper
