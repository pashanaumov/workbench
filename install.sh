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
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin}
  cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/"
  cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/"
  cp -r "$SCRIPT_DIR/templates/"* "$TARGET/templates/"
  cp -r "$SCRIPT_DIR/bin/"* "$TARGET/bin/"
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
  
  mkdir -p "$TARGET"/{skills,hooks,memory,session-memory,templates,.tmp,bin}
  cp -r "$TMP_DIR/workbench/skills/"* "$TARGET/skills/"
  cp -r "$TMP_DIR/workbench/hooks/"* "$TARGET/hooks/"
  cp -r "$TMP_DIR/workbench/templates/"* "$TARGET/templates/"
  cp -r "$TMP_DIR/workbench/bin/"* "$TARGET/bin/"
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

# PATH setup
if [[ "$TARGET" == "$HOME/.workbench" ]]; then
  PATH_EXPORT="export PATH=\"\$HOME/.workbench/bin:\$PATH\""
  
  add_to_shell_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
      if ! grep -q "\.workbench/bin" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "# Workbench" >> "$rc_file"
        echo "$PATH_EXPORT" >> "$rc_file"
        printf "${DIM}${BAR}${RESET}  ${GREEN}${CHECK}${RESET} Added to ${CYAN}$rc_file${RESET}\n"
        return 0
      else
        printf "${DIM}${BAR}${RESET}  ${DIM}○ Already in${RESET} ${CYAN}$rc_file${RESET}\n"
        return 1
      fi
    fi
    return 1
  }
  
  printf "${DIM}┌${RESET}\n"
  ADDED=false
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if add_to_shell_rc "$rc"; then
      ADDED=true
    fi
  done
  printf "${DIM}└${RESET}\n"
  
  if [ "$ADDED" = true ]; then
    printf "\n"
    printf "${DIM}Restart your shell or run:${RESET} ${CYAN}source ~/.zshrc${RESET}\n"
  fi
  
  printf "\n"
  printf "${BOLD}Next steps${RESET}\n"
  printf "${DIM}┌${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}wb doctor${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}wb print steering-doc${RESET}  ${DIM}# Add to your AI tool${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}wb install copilot${RESET}    ${DIM}# Optional: Install hooks${RESET}\n"
  printf "${DIM}└${RESET}\n"
else
  printf "${BOLD}Next steps${RESET}\n"
  printf "${DIM}┌${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}export PATH=\"$(pwd)/$TARGET/bin:\$PATH\"${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}$TARGET/bin/wb doctor${RESET}\n"
  printf "${DIM}${BAR}${RESET}  ${CYAN}$TARGET/bin/wb print steering-doc${RESET}\n"
  printf "${DIM}└${RESET}\n"
fi

printf "\n"
