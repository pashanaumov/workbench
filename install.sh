#!/usr/bin/env bash
set -euo pipefail

# Workbench installer
# Usage: ./install.sh [target_dir]
# Or:    curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench.sh/main/install.sh | bash

REPO="https://github.com/pashanaumov/workbench.git"
TARGET="${1:-$HOME/.workbench}"

echo "Installing workbench to: $TARGET"

# Detect if running from a local clone or via curl
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/config.yaml" ]; then
  # Local execution — copy from repo
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp}
  cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/"
  cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/"
  cp -r "$SCRIPT_DIR/templates/"* "$TARGET/templates/"
  cp "$SCRIPT_DIR/config.yaml" "$TARGET/config.yaml"
  cp "$SCRIPT_DIR/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"
else
  # Curl execution — clone the repo
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for installation" >&2
    exit 1
  fi
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  git clone --depth=1 "$REPO" "$TMP_DIR/workbench" >/dev/null 2>&1
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp}
  cp -r "$TMP_DIR/workbench/skills/"* "$TARGET/skills/"
  cp -r "$TMP_DIR/workbench/hooks/"* "$TARGET/hooks/"
  cp -r "$TMP_DIR/workbench/templates/"* "$TARGET/templates/"
  cp "$TMP_DIR/workbench/config.yaml" "$TARGET/config.yaml"
  cp "$TMP_DIR/workbench/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"
fi

# Make hook scripts executable
find "$TARGET/hooks" -name "*.sh" -type f -exec chmod +x {} \;

# Seed empty dirs
touch "$TARGET/memory/.gitkeep"
touch "$TARGET/session-memory/.gitkeep"

echo ""
echo "✓ Workbench installed successfully"
echo ""
echo "Next steps:"
echo "  1. Add steering doc to your AI tool (see $TARGET/templates/steering-doc-template.md)"
echo "  2. Optional: Install Copilot hooks with 'workbench install copilot'"
echo "  3. Verify installation with '$TARGET/bin/workbench doctor'"
echo ""
