#!/usr/bin/env bash
set -euo pipefail

# Workbench installer
# Usage: ./install.sh [target_dir]
# Or:    curl -fsSL https://raw.githubusercontent.com/pashanaumov/workbench.sh/main/install.sh | bash

REPO="https://github.com/pashanaumov/workbench.git"

# If target not provided, ask user
if [ -z "${1:-}" ]; then
  echo "Workbench Installation"
  echo "======================"
  echo ""
  echo "Where would you like to install workbench?"
  echo ""
  echo "1) Global (~/.workbench) - Available across all projects"
  echo "2) Local (.workbench) - Only in this project directory"
  echo ""
  read -p "Choose [1/2] (default: 1): " INSTALL_CHOICE
  INSTALL_CHOICE=${INSTALL_CHOICE:-1}
  
  case "$INSTALL_CHOICE" in
    1)
      TARGET="$HOME/.workbench"
      echo ""
      echo "Installing globally to: $TARGET"
      ;;
    2)
      TARGET=".workbench"
      echo ""
      echo "Installing locally to: $(pwd)/$TARGET"
      ;;
    *)
      echo "Invalid choice. Installing globally to: $HOME/.workbench"
      TARGET="$HOME/.workbench"
      ;;
  esac
else
  TARGET="$1"
  echo "Installing workbench to: $TARGET"
fi

echo ""

# Detect if running from a local clone or via curl
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/config.yaml" ]; then
  # Local execution — copy from repo
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin}
  cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/"
  cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/"
  cp -r "$SCRIPT_DIR/templates/"* "$TARGET/templates/"
  cp -r "$SCRIPT_DIR/bin/"* "$TARGET/bin/"
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
  
  # Debug: show what was cloned
  if [ ! -d "$TMP_DIR/workbench/skills" ]; then
    echo "Error: skills directory not found after clone" >&2
    echo "Contents of $TMP_DIR/workbench:" >&2
    ls -la "$TMP_DIR/workbench/" >&2
    exit 1
  fi
  
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin}
  cp -r "$TMP_DIR/workbench/skills/"* "$TARGET/skills/"
  cp -r "$TMP_DIR/workbench/hooks/"* "$TARGET/hooks/"
  cp -r "$TMP_DIR/workbench/templates/"* "$TARGET/templates/"
  cp -r "$TMP_DIR/workbench/bin/"* "$TARGET/bin/"
  cp "$TMP_DIR/workbench/config.yaml" "$TARGET/config.yaml"
  cp "$TMP_DIR/workbench/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"
fi

# Make hook scripts executable
find "$TARGET/hooks" -name "*.sh" -type f -exec chmod +x {} \;

# Make bin scripts executable (including wb alias)
chmod +x "$TARGET/bin/"*

# Seed empty dirs
touch "$TARGET/memory/.gitkeep"
touch "$TARGET/session-memory/.gitkeep"

# Prompt for MemPalace integration
echo ""
echo "MemPalace Integration"
echo "====================="
echo "MemPalace provides enhanced context loading and semantic memory search."
echo ""

if command -v mempalace >/dev/null 2>&1; then
  echo "✓ MemPalace is installed at: $(command -v mempalace)"
  echo ""
  read -p "Enable MemPalace integration? (y/n/later) [later]: " MEMPALACE_CHOICE
  MEMPALACE_CHOICE=${MEMPALACE_CHOICE:-later}
else
  echo "○ MemPalace is not installed"
  echo ""
  read -p "Install and enable MemPalace? (y/n/later) [later]: " MEMPALACE_CHOICE
  MEMPALACE_CHOICE=${MEMPALACE_CHOICE:-later}
  
  if [[ "$MEMPALACE_CHOICE" =~ ^[yY]([eE][sS])?$ ]]; then
    echo ""
    echo "Installing MemPalace..."
    
    if command -v npm >/dev/null 2>&1; then
      npm install -g @mempalace/cli
      if command -v mempalace >/dev/null 2>&1; then
        echo "  ✓ MemPalace installed successfully"
      else
        echo "  ✗ MemPalace installation failed"
        MEMPALACE_CHOICE="later"
      fi
    elif command -v brew >/dev/null 2>&1; then
      brew install mempalace
      if command -v mempalace >/dev/null 2>&1; then
        echo "  ✓ MemPalace installed successfully"
      else
        echo "  ✗ MemPalace installation failed"
        MEMPALACE_CHOICE="later"
      fi
    else
      echo "  ✗ Neither npm nor brew found. Cannot install MemPalace."
      echo "  Install manually: npm install -g @mempalace/cli"
      MEMPALACE_CHOICE="later"
    fi
  fi
fi

case "$MEMPALACE_CHOICE" in
  y|Y|yes|Yes|YES)
    sed -i.bak 's/enabled: auto/enabled: true/' "$TARGET/config.yaml" && rm "$TARGET/config.yaml.bak"
    echo "  → MemPalace enabled"
    ;;
  n|N|no|No|NO)
    sed -i.bak 's/enabled: auto/enabled: false/' "$TARGET/config.yaml" && rm "$TARGET/config.yaml.bak"
    echo "  → MemPalace disabled"
    ;;
  *)
    echo "  → MemPalace set to auto-detect (default)"
    ;;
esac

# Add to PATH automatically
PATH_EXPORT="export PATH=\"\$HOME/.workbench/bin:\$PATH\""

add_to_shell_rc() {
  local rc_file="$1"
  if [ -f "$rc_file" ]; then
    if ! grep -q "\.workbench/bin" "$rc_file"; then
      echo "" >> "$rc_file"
      echo "# Workbench" >> "$rc_file"
      echo "$PATH_EXPORT" >> "$rc_file"
      echo "  ✓ Added to $rc_file"
      return 0
    else
      echo "  ○ Already in $rc_file"
      return 1
    fi
  fi
  return 1
}

echo ""
echo "✓ Workbench installed successfully"
echo ""

# Add to PATH automatically (only for global installation)
if [[ "$TARGET" == "$HOME/.workbench" ]]; then
  echo "Adding to PATH..."
  
  PATH_EXPORT="export PATH=\"\$HOME/.workbench/bin:\$PATH\""
  
  add_to_shell_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
      if ! grep -q "\.workbench/bin" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "# Workbench" >> "$rc_file"
        echo "$PATH_EXPORT" >> "$rc_file"
        echo "  ✓ Added to $rc_file"
        return 0
      else
        echo "  ○ Already in $rc_file"
        return 1
      fi
    fi
    return 1
  }
  
  ADDED=false
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if add_to_shell_rc "$rc"; then
      ADDED=true
    fi
  done
  
  if [ "$ADDED" = true ]; then
    echo ""
    echo "Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
  else
    echo "  ○ PATH already configured or no shell rc files found"
  fi
  
  echo ""
  echo "Next steps:"
  echo "  1. Run: wb doctor"
  echo "  2. Add steering doc to your AI tool: wb print steering-doc"
  echo "  3. Optional: Install Copilot hooks with 'wb install copilot'"
else
  echo "Local installation complete."
  echo ""
  echo "To use workbench commands in this project:"
  echo "  export PATH=\"$(pwd)/$TARGET/bin:\$PATH\""
  echo ""
  echo "Or use full path:"
  echo "  $TARGET/bin/wb doctor"
  echo ""
  echo "Next steps:"
  echo "  1. Run: $TARGET/bin/wb doctor"
  echo "  2. Add steering doc: $TARGET/bin/wb print steering-doc"
  echo "  3. Install Copilot hooks: $TARGET/bin/wb install copilot"
fi

echo ""
