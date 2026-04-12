#!/usr/bin/env bash
# Shared helper for detecting optional integrations
# Source this file in hooks that need integration detection

# Install MemPalace if needed
install_mempalace() {
  local install_dir="${HOME}/.local/bin"
  mkdir -p "$install_dir"
  
  # Download and install
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/MemPalace/mempalace/main/install.sh | bash
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://raw.githubusercontent.com/MemPalace/mempalace/main/install.sh | bash
  else
    return 1
  fi
}

# Detect if MemPalace is enabled
# Returns 0 (true) if enabled, 1 (false) if disabled
# Auto-installs if config is true and mempalace is missing
mempalace_enabled() {
  local workbench_root="${WORKBENCH_ROOT:-$HOME/.workbench}"
  local config_file="$workbench_root/config.yaml"
  local config_value="auto"
  
  # Read config if it exists
  if [ -f "$config_file" ]; then
    if command -v yq >/dev/null 2>&1; then
      config_value=$(yq e '.integrations.mempalace.enabled // "auto"' "$config_file")
    else
      # Fallback: grep + awk
      config_value=$(grep -A2 'mempalace:' "$config_file" | grep 'enabled:' | awk '{print $2}' || echo "auto")
    fi
  fi
  
  # Handle config value
  case "$config_value" in
    true)
      # Force enabled - install if missing
      if ! command -v mempalace >/dev/null 2>&1; then
        install_mempalace >/dev/null 2>&1 || return 1
      fi
      return 0
      ;;
    false)
      return 1
      ;;
    auto|*)
      # Auto-detect from PATH
      if command -v mempalace >/dev/null 2>&1; then
        return 0
      else
        return 1
      fi
      ;;
  esac
}
