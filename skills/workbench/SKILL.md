---
name: workbench
description: Configure workbench settings and integrations. Use when user wants to configure workbench, toggle features, or check status.
argument-hint: "[command] [args...]"
---

# Workbench Configuration

Interactive configuration and status management for workbench.

## Commands

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

## Usage Examples

```
/workbench status
/workbench mode hybrid
/workbench mempalace on
/workbench dream off
/workbench config
/workbench config set dream.min_sessions 3
```

## Notes

- All config changes are immediate
- Invalid keys will show an error
- Use `workbench doctor` CLI command for health checks
