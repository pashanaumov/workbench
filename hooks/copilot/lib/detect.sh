#!/usr/bin/env bash
# Shared helper for detecting optional integrations
# Source this file in hooks that need integration detection

find_nearest_workbench_root() {
  local dir="${1:-$(pwd)}"
  if [ -z "$dir" ]; then
    return 1
  fi

  while true; do
    if [ -f "$dir/.workbench/config.yaml" ]; then
      printf '%s\n' "$dir/.workbench"
      return 0
    fi
    local parent
    parent="$(dirname "$dir")"
    if [ "$parent" = "$dir" ]; then
      break
    fi
    dir="$parent"
  done

  return 1
}

resolve_workbench_root() {
  local cwd="${1:-}"

  if [ -n "${WORKBENCH_ROOT:-}" ]; then
    printf '%s\n' "$WORKBENCH_ROOT"
    return 0
  fi

  local detected=""
  if [ -n "$cwd" ]; then
    detected="$(find_nearest_workbench_root "$cwd" || true)"
  fi
  if [ -z "$detected" ]; then
    detected="$(find_nearest_workbench_root "$(pwd)" || true)"
  fi

  if [ -n "$detected" ]; then
    printf '%s\n' "$detected"
  else
    printf '%s\n' "$HOME/.workbench"
  fi
}

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
  local workbench_root
  workbench_root="$(resolve_workbench_root "${1:-}")"
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
