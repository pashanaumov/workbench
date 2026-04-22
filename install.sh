#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/pashanaumov/workbench.git"

# Colors
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'

# Box drawing
BAR="│"
STEP="◆"
CHECK="✔"
ARROW="→"

printf "\n"

# If target not provided, ask user
if [ -z "${1:-}" ]; then
  printf "${CYAN}${STEP}${RESET}  Where would you like to install workbench?\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${BOLD}1${RESET}  Global ${DIM}(~/.workbench)${RESET}\n"
  printf "${DIM}${BAR}${RESET}     ${DIM}Available across all projects${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${BOLD}2${RESET}  Local ${DIM}(.workbench)${RESET}\n"
  printf "${DIM}${BAR}${RESET}     ${DIM}Only in this project directory${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${GREEN}?${RESET}  Choose ${DIM}[1/2] (default: 1)${RESET} ${ARROW} "
  read INSTALL_CHOICE </dev/tty
  INSTALL_CHOICE=${INSTALL_CHOICE:-1}
  
  case "$INSTALL_CHOICE" in
    1)
      TARGET="$HOME/.workbench"
      printf "${GREEN}${CHECK}${RESET}  Installing globally to ${CYAN}$TARGET${RESET}\n"
      ;;
    2)
      TARGET=".workbench"
      printf "${GREEN}${CHECK}${RESET}  Installing locally to ${CYAN}$(pwd)/$TARGET${RESET}\n"
      ;;
    *)
      TARGET="$HOME/.workbench"
      printf "${GREEN}${CHECK}${RESET}  Installing globally to ${CYAN}$TARGET${RESET}\n"
      ;;
  esac
else
  TARGET="$1"
  printf "${GREEN}${CHECK}${RESET}  Installing to ${CYAN}$TARGET${RESET}\n"
fi

printf "\n"

# Clone/copy files
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/config.yaml" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin,packages}
  cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/"
  cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/"
  cp -r "$SCRIPT_DIR/templates/"* "$TARGET/templates/"
  cp -r "$SCRIPT_DIR/bin/"* "$TARGET/bin/"
  cp -r "$SCRIPT_DIR/packages/core" "$TARGET/packages/"
  cp -r "$SCRIPT_DIR/packages/mcp" "$TARGET/packages/"
  cp "$SCRIPT_DIR/config.yaml" "$TARGET/config.yaml"
  cp "$SCRIPT_DIR/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"
else
  if ! command -v git >/dev/null 2>&1; then
    printf "${DIM}${BAR}${RESET}\n"
    printf "${DIM}└${RESET}  git is required for installation\n\n"
    exit 1
  fi
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  git clone --depth=1 "$REPO" "$TMP_DIR/workbench" >/dev/null 2>&1
  
  if [ ! -d "$TMP_DIR/workbench/skills" ]; then
    printf "${DIM}${BAR}${RESET}\n"
    printf "${DIM}└${RESET}  skills directory not found after clone\n\n"
    exit 1
  fi
  
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin,packages}
  cp -r "$TMP_DIR/workbench/skills/"* "$TARGET/skills/"
  cp -r "$TMP_DIR/workbench/hooks/"* "$TARGET/hooks/"
  cp -r "$TMP_DIR/workbench/templates/"* "$TARGET/templates/"
  cp -r "$TMP_DIR/workbench/bin/"* "$TARGET/bin/"
  cp -r "$TMP_DIR/workbench/packages/core" "$TARGET/packages/"
  cp -r "$TMP_DIR/workbench/packages/mcp" "$TARGET/packages/"
  cp "$TMP_DIR/workbench/config.yaml" "$TARGET/config.yaml"
  cp "$TMP_DIR/workbench/memory/MEMORY.md" "$TARGET/memory/MEMORY.md"
fi

find "$TARGET/hooks" -name "*.sh" -type f -exec chmod +x {} \;
chmod +x "$TARGET/bin/"*
touch "$TARGET/memory/.gitkeep"
touch "$TARGET/session-memory/.gitkeep"

# MemPalace integration
printf "${CYAN}${STEP}${RESET}  MemPalace Integration\n"
printf "${DIM}${BAR}${RESET}\n"
printf "${DIM}${BAR}${RESET}  ${DIM}Enhanced context loading and semantic memory search${RESET}\n"
printf "${DIM}${BAR}${RESET}\n"

if command -v mempalace >/dev/null 2>&1; then
  printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} MemPalace installed at ${CYAN}$(command -v mempalace)${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${GREEN}?${RESET}  Enable MemPalace? ${DIM}(y/n/later) [later]${RESET} ${ARROW} "
  read MEMPALACE_CHOICE </dev/tty
  MEMPALACE_CHOICE=${MEMPALACE_CHOICE:-later}
else
  printf "${DIM}${BAR}${RESET}  ${YELLOW}○${RESET} MemPalace not installed\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${GREEN}?${RESET}  Install MemPalace? ${DIM}(y/n/later) [later]${RESET} ${ARROW} "
  read MEMPALACE_CHOICE </dev/tty
  MEMPALACE_CHOICE=${MEMPALACE_CHOICE:-later}
  
  if [[ "$MEMPALACE_CHOICE" =~ ^[yY]([eE][sS])?$ ]]; then
    printf "${DIM}${BAR}${RESET}\n"
    printf "${DIM}${BAR}${RESET}  Installing MemPalace...\n"
    
    if command -v npm >/dev/null 2>&1; then
      npm install -g @mempalace/cli >/dev/null 2>&1
      if command -v mempalace >/dev/null 2>&1; then
        printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Installed successfully\n"
      else
        printf "${DIM}${BAR}${RESET}  ${YELLOW}!${RESET} Installation failed\n"
        MEMPALACE_CHOICE="later"
      fi
    elif command -v brew >/dev/null 2>&1; then
      brew install mempalace >/dev/null 2>&1
      if command -v mempalace >/dev/null 2>&1; then
        printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Installed successfully\n"
      else
        printf "${DIM}${BAR}${RESET}  ${YELLOW}!${RESET} Installation failed\n"
        MEMPALACE_CHOICE="later"
      fi
    else
      printf "${DIM}${BAR}${RESET}  ${YELLOW}!${RESET} Neither npm nor brew found\n"
      printf "${DIM}${BAR}${RESET}  ${DIM}Install manually: npm install -g @mempalace/cli${RESET}\n"
      MEMPALACE_CHOICE="later"
    fi
  fi
fi

case "$MEMPALACE_CHOICE" in
  y|Y|yes|Yes|YES)
    sed -i.bak 's/enabled: auto/enabled: true/' "$TARGET/config.yaml" && rm "$TARGET/config.yaml.bak"
    printf "${DIM}${BAR}${RESET}  ${ARROW} Enabled\n"
    ;;
  n|N|no|No|NO)
    sed -i.bak 's/enabled: auto/enabled: false/' "$TARGET/config.yaml" && rm "$TARGET/config.yaml.bak"
    printf "${DIM}${BAR}${RESET}  ${ARROW} Disabled\n"
    ;;
  *)
    printf "${DIM}${BAR}${RESET}  ${ARROW} Auto-detect\n"
    ;;
esac

printf "\n"
printf "${GREEN}${CHECK}${RESET}  ${BOLD}Installation complete${RESET}\n"
printf "\n"

# PATH setup (global only)
if [[ "$TARGET" == "$HOME/.workbench" ]]; then
  PATH_EXPORT="export PATH=\"\$HOME/.workbench/bin:\$PATH\""
  
  add_to_shell_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
      if ! grep -q "\.workbench/bin" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "# Workbench" >> "$rc_file"
        echo "$PATH_EXPORT" >> "$rc_file"
        printf "  ${GREEN}${CHECK}${RESET} ${DIM}Added to${RESET} ${CYAN}$rc_file${RESET}\n"
        return 0
      else
        printf "  ${DIM}○ Already in${RESET} ${CYAN}$rc_file${RESET}\n"
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
    printf "\n"
    printf "${DIM}Restart your shell or run:${RESET} ${CYAN}source ~/.zshrc${RESET}\n"
  fi
fi

# Agent setup
printf "\n"
printf "${CYAN}${STEP}${RESET}  Which AI tool do you use?\n"
printf "${DIM}${BAR}${RESET}\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}1${RESET}  Universal ${DIM}(.agents) - Works with most tools${RESET}\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}2${RESET}  GitHub Copilot ${DIM}(cloud agent or CLI)${RESET}\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}3${RESET}  Cursor\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}4${RESET}  Windsurf\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}5${RESET}  Kiro / Claude Code\n"
printf "${DIM}${BAR}${RESET}  ${BOLD}6${RESET}  Skip\n"
printf "${DIM}${BAR}${RESET}\n"
printf "${GREEN}?${RESET}  Choose ${DIM}[1-6] (default: 1)${RESET} ${ARROW} "
read AGENT_CHOICE </dev/tty
AGENT_CHOICE=${AGENT_CHOICE:-1}

STEERING_DOC_FILE=""
SKILLS_DIR=""
GLOBAL_SKILLS_DIR=""
NEEDS_HOOKS=false
AGENT_LABEL=""

case "$AGENT_CHOICE" in
  1) STEERING_DOC_FILE="AGENTS.md"; SKILLS_DIR=".agents/skills"; GLOBAL_SKILLS_DIR="$HOME/.config/agents/skills"; AGENT_LABEL="Universal (.agents)" ;;
  2) STEERING_DOC_FILE=".github/copilot-instructions.md"; SKILLS_DIR=".agents/skills"; GLOBAL_SKILLS_DIR="$HOME/.copilot/skills"; NEEDS_HOOKS=true; AGENT_LABEL="GitHub Copilot" ;;
  3) STEERING_DOC_FILE=".cursorrules"; SKILLS_DIR=".cursor/skills"; GLOBAL_SKILLS_DIR="$HOME/.cursor/skills"; AGENT_LABEL="Cursor" ;;
  4) STEERING_DOC_FILE=".windsurfrules"; SKILLS_DIR=".windsurf/skills"; GLOBAL_SKILLS_DIR="$HOME/.windsurf/skills"; AGENT_LABEL="Windsurf" ;;
  5) STEERING_DOC_FILE="AGENTS.md"; SKILLS_DIR=".kiro/skills"; GLOBAL_SKILLS_DIR="$HOME/.kiro/skills"; AGENT_LABEL="Kiro / Claude Code" ;;
  *) printf "${DIM}${BAR}${RESET}  ${ARROW} Skipped\n" ;;
esac

if [ -n "$SKILLS_DIR" ]; then
  printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} ${CYAN}$AGENT_LABEL${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"

  # Ask for agent integration scope
  printf "${DIM}${BAR}${RESET}  ${BOLD}Where to install agent integration?${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${BOLD}1${RESET}  Project ${DIM}(current directory)${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${BOLD}2${RESET}  Global ${DIM}(home directory)${RESET}\n"
  printf "${DIM}${BAR}${RESET}\n"
  printf "${GREEN}?${RESET}  Choose ${DIM}[1-2] (default: 1)${RESET} ${ARROW} "
  read INTEGRATION_SCOPE </dev/tty
  INTEGRATION_SCOPE=${INTEGRATION_SCOPE:-1}

  if [ "$INTEGRATION_SCOPE" = "2" ]; then
    # Global agent integration
    INSTALL_SKILLS_DIR="$GLOBAL_SKILLS_DIR"
    INSTALL_STEERING_DOC="$HOME/$STEERING_DOC_FILE"
  else
    # Project agent integration
    INSTALL_SKILLS_DIR="$SKILLS_DIR"
    INSTALL_STEERING_DOC="$STEERING_DOC_FILE"
  fi

  printf "${DIM}${BAR}${RESET}\n"

  # Install skills
  mkdir -p "$INSTALL_SKILLS_DIR"
  for skill in "$TARGET/skills/"*; do
    skill_name=$(basename "$skill")
    if [ -d "$skill" ] && [ -f "$skill/SKILL.md" ]; then
      ln -sf "$skill" "$INSTALL_SKILLS_DIR/$skill_name" 2>/dev/null || cp -r "$skill" "$INSTALL_SKILLS_DIR/$skill_name"
    fi
  done
  printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Skills installed to ${CYAN}$INSTALL_SKILLS_DIR${RESET}\n"

  # Install hooks for Copilot (project only)
  if [ "$NEEDS_HOOKS" = true ] && [ "$INTEGRATION_SCOPE" = "1" ]; then
    mkdir -p ".github/hooks/copilot"
    cp -r "$TARGET/hooks/copilot/"* ".github/hooks/copilot/"
    chmod +x ".github/hooks/copilot/"*.sh
    printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Hooks installed to ${CYAN}.github/hooks/copilot/${RESET}\n"
    printf "${DIM}${BAR}${RESET}  ${DIM}→ For cloud agent: commit .github/hooks/ to default branch${RESET}\n"
    printf "${DIM}${BAR}${RESET}  ${DIM}→ For CLI: hooks work immediately${RESET}\n"
  fi

  # Write steering doc
  printf "${DIM}${BAR}${RESET}\n"
  mkdir -p "$(dirname "$INSTALL_STEERING_DOC")"
  if [ -f "$INSTALL_STEERING_DOC" ] && grep -q "Workbench Memory System" "$INSTALL_STEERING_DOC" 2>/dev/null; then
    printf "${DIM}${BAR}${RESET}  ${DIM}○ Steering doc already in${RESET} ${CYAN}$INSTALL_STEERING_DOC${RESET}\n"
  else
    printf "\n" >> "$INSTALL_STEERING_DOC"
    cat "$TARGET/templates/steering-doc-template.md" >> "$INSTALL_STEERING_DOC"
    printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Steering doc added to ${CYAN}$INSTALL_STEERING_DOC${RESET}\n"
  fi
fi

printf "\n"
printf "${BOLD}Done!${RESET} ${DIM}Run${RESET} ${CYAN}wb doctor${RESET} ${DIM}to verify.${RESET}\n"
printf "\n"
