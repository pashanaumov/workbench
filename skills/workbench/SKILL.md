---
name: workbench
description: Configure workbench settings and integrations. Use when user wants to configure workbench, toggle features, enable/disable the codebase indexer MCP, or check status.
argument-hint: "[command] [args...]"
---

# Workbench Configuration

Interactive configuration and status management for workbench.

Path convention: resolve `<workbenchRoot>` first.
- If `WORKBENCH_ROOT` is set, use it.
- Otherwise, if `.workbench/config.yaml` exists in the current project (or parent), use that `.workbench` path.
- Otherwise, use `~/.workbench`.

## Commands

### `setup`
Add workbench steering doc to the current AI tool's configuration file.

**Steps:**
1. Detect the current AI tool by checking for config files:
   - `.github/copilot-instructions.md` → GitHub Copilot
   - `AGENTS.md` → Kiro CLI / Claude Code
   - `.cursorrules` → Cursor
   - `.windsurfrules` → Windsurf
2. Read the steering doc template from `<workbenchRoot>/templates/steering-doc-template.md`
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
1. Read `<workbenchRoot>/config.yaml`
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
1. Read `<workbenchRoot>/config.yaml`
2. Update `mode` to the specified value
3. Write back to config file
4. Explain what the mode means:
   - **global**: Only use `<workbenchRoot>/` (skills, memory, config)
   - **local**: Only use `.workbench/` in project root
   - **hybrid**: Check both, project-local overrides global
5. Confirm the change

### `mempalace on|off`
Enable or disable MemPalace integration.

**Steps:**
1. Read `<workbenchRoot>/config.yaml`
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
1. Read `<workbenchRoot>/config.yaml`
2. Update `dream.enabled` to `true` or `false`
3. Write back to config file
4. Confirm the change

### `config`
Show full configuration file.

**Steps:**
1. Read and display `<workbenchRoot>/config.yaml`

### `config set <key> <value>`
Update a configuration value.

**Steps:**
1. Read `<workbenchRoot>/config.yaml`
2. Update the specified key (supports dot notation: `dream.min_sessions`)
3. Write back to config file
4. Confirm the change

### `gh hooks init`

Deploy Copilot CLI hooks to the current project's `.github/hooks/` directory.

Hooks can only be loaded per-project (Copilot CLI reads from `.github/hooks/` in the CWD).
Skills can be global; hooks cannot. This command bridges that gap.

**Steps:**
1. Verify `<workbenchRoot>/hooks/copilot/` exists as the source
2. Check if `.github/hooks/copilot/` already exists — if so, confirm with the user before overwriting
3. Run:
   ```bash
   mkdir -p .github/hooks
   cp -r <workbenchRoot>/hooks/copilot .github/hooks/
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

Register the workbench-indexer MCP server so it is auto-started in supported MCP clients (Claude Code and Kiro).

**Steps:**

1. **Resolve the active workbench root (`<workbenchRoot>`).** Check in this order:
   - If `WORKBENCH_ROOT` is set, use it.
   - Otherwise, if current directory (or parent) has `.workbench/config.yaml`, use that `.workbench`.
   - Otherwise use `~/.workbench`.

2. **Find the repo root.** Check in this order:
   - Does the current directory contain a complete workbench repo (`package.json`, `pnpm-workspace.yaml`, and `packages/mcp/src/index.ts`)? → use `pwd`
   - Does `<workbenchRoot>` contain that same complete repo shape? → use `<workbenchRoot>`
   - Does `<workbenchRoot>/indexer.json` exist and contain a valid complete `repoRoot`? → use that
   - Try common locations: `~/workbench`, `~/projects/workbench`, `~/code/workbench`, `~/Desktop/workbench`
   - If none found, ask the user: "Where is the workbench repo cloned? (full path)"

3. **Prepare runtime** in `<repoRoot>`:
   - Ensure Node.js is available.
   - Ensure `pnpm` or `corepack` is available.
   - Run:
     ```bash
     cd "<repoRoot>"
     corepack pnpm install
     corepack pnpm run build
     ```
   - Verify `<repoRoot>/packages/mcp/dist/index.js` exists after build.

4. **Generate `<workbenchRoot>/bin/workbench-mcp`** — a small wrapper script:
   ```bash
   #!/usr/bin/env bash
   # Generated by: /workbench indexer enable
   # Workbench indexer MCP server launcher
   exec node "<repoRoot>/packages/mcp/dist/index.js"
   ```
   Then `chmod +x <workbenchRoot>/bin/workbench-mcp`.

5. **Save repo root** to `<workbenchRoot>/indexer.json`:
   ```json
   { "repoRoot": "<repoRoot>" }
   ```

6. **Edit client MCP config files** (depends on `--client`, default `all`):
   - Claude Code: `~/.claude/.mcp.json`
   - Kiro: `~/.kiro/settings/mcp.json`
   - If a file does not exist, create it with `{ "mcpServers": {} }`
   - Add or overwrite the `workbench-indexer` key in each selected client:
    ```json
    "workbench-indexer": {
      "command": "<workbenchRoot>/bin/workbench-mcp",
      "disabled": false,
      "autoApprove": ["search_code", "get_indexing_status"]
   }
   ```
   - Write the file back (preserve all other entries).

7. **Confirm:**
   ```
    ✓ workbench-mcp wrapper written to <workbenchRoot>/bin/workbench-mcp
    ✓ workbench-indexer configured in Claude Code
    ✓ workbench-indexer configured in Kiro

    Next steps:
      1. Run `workbench index` in your project (downloads model + grammars on first run, ~400 MB)
      2. Restart your MCP client(s)
      3. In your project, ask your agent to "index this codebase"
    ```

---

### `indexer disable`

Disable the workbench-indexer MCP server without removing its configuration.

**Steps:**

1. Resolve selected clients by `--client` (`claude`, `kiro`, or `all`).
2. For each selected MCP config file, if `workbench-indexer` exists, set `mcpServers.workbench-indexer.disabled = true`.
3. If none are configured, say "Indexer is not configured — run `/workbench indexer enable` first."
4. Confirm:
   ```
   ✓ workbench-indexer disabled in Claude Code
   ✓ workbench-indexer disabled in Kiro
   Restart your MCP client(s) to apply.
   Run `/workbench indexer enable` to re-enable.
   ```

---

### `indexer status`

Show the current state of the indexer: MCP registration, model setup, and index for the current project.

**Steps:**

1. **MCP registration** — for selected clients (`--client`, default `all`):
   - Not present → `○ Not configured`
   - Present, `disabled: true` → `⚠ Registered but disabled`
   - Present, enabled → `✓ Registered and active`

2. **Model setup** — check `<workbenchRoot>/grammars/tree-sitter-python.wasm` exists AND `<workbenchRoot>/models/jinaai` (or any subdirectory) has `.onnx` files:
   - Missing → `✗ Setup not done — run: workbench index (triggers auto-setup)`
   - Present → `✓ Model and grammars ready`

3. **Project index** — compute the project hash from cwd:
   - Hash = first 12 chars of `sha256(cwd)` (hex)
   - Check `<workbenchRoot>/<hash>/stats.json`
   - Missing → `○ No index for this project yet`
   - Present → parse and show:
     ```
     ✓ Index: <workbenchRoot>/<hash>/
       Last indexed: <lastIndexedAt as human date>
       Chunks: <chunkCount>
     ```

4. **Print summary** — example output:
   ```
   Workbench Indexer Status
   ═════════════════════════
   MCP clients:
     Claude Code: ✓ Registered and active
     Kiro: ○ Not configured
   Model/grammars: ✓ Ready
   Project index:  ✓ 847 chunks (last indexed: 2 hours ago)

   Project:  /Users/you/your-project
   Index at: <workbenchRoot>/a3f9b21c4d8e/
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
- If you move the workbench repo, re-run `/workbench indexer enable` from the new location to regenerate the `workbench-mcp` wrapper
