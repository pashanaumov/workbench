#!/usr/bin/env bash
set -euo pipefail

# Colors
RESET='\033[0m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
DIM='\033[2m'

printf "\n"
printf "${CYAN}Uninstalling workbench...${RESET}\n\n"

# Remove directory
if [ -d "$HOME/.workbench" ]; then
  rm -rf "$HOME/.workbench"
  printf "${GREEN}✔${RESET}  Removed ${CYAN}~/.workbench${RESET}\n"
else
  printf "${DIM}○${RESET}  ${DIM}~/.workbench not found${RESET}\n"
fi

# Remove from shell configs
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$rc" ] && grep -q "\.workbench/bin" "$rc"; then
    # Remove the Workbench section (comment + export line)
    sed -i.bak '/# Workbench/,/export PATH.*\.workbench\/bin/d' "$rc"
    rm -f "$rc.bak"
    printf "${GREEN}✔${RESET}  Cleaned ${CYAN}$rc${RESET}\n"
  fi
done

printf "\n${GREEN}✔${RESET}  ${DIM}Uninstall complete${RESET}\n\n"
