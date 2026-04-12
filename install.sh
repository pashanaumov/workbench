#!/usr/bin/env bash
set -euo pipefail

# Workbench installer
# Usage: ./install.sh [target_dir]

TARGET="${1:-$HOME/.workbench}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing workbench to: $TARGET"

# Create directories
mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp}

# Copy files
cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/templates/"* "$TARGET/templates/" 2>/dev/null || true
cp "$SCRIPT_DIR/config.yaml" "$TARGET/config.yaml"
cp "$SCRIPT_DIR/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"

# Make hook scripts executable
find "$TARGET/hooks" -name "*.sh" -type f -exec chmod +x {} \;

# Create .gitkeep files
touch "$TARGET/memory/.gitkeep"
touch "$TARGET/session-memory/.gitkeep"

echo ""
echo "✓ Workbench installed successfully"
echo ""
echo "Next steps:"
echo "  1. Add steering doc to your AI tool (see templates/steering-doc-template.md)"
echo "  2. Optional: Install Copilot hooks with 'workbench install copilot'"
echo "  3. Verify installation with 'workbench doctor'"
echo ""
