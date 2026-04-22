---
name: workbench
description: Configure workbench settings and integrations. Use when user wants to configure workbench, toggle features, or check status.
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
```

## Notes

- All config changes are immediate
- Invalid keys will show an error
- Use `workbench doctor` CLI command for health checks
