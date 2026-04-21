#!/usr/bin/env bash
set -euo pipefail

# Colors
RESET='\033[0m'
CYAN='\033[36m'
GREEN='\033[32m'
DIM='\033[2m'

printf "\n"
printf "${CYAN}Uninstalling workbench...${RESET}\n\n"

# Remove global directory
if [ -d "$HOME/.workbench" ]; then
  rm -rf "$HOME/.workbench"
  printf "${GREEN}✔${RESET}  Removed ${CYAN}~/.workbench${RESET}\n"
else
  printf "${DIM}○${RESET}  ${DIM}~/.workbench not found${RESET}\n"
fi

# Remove from shell configs
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$rc" ] && grep -q "\.workbench/bin" "$rc"; then
    sed -i.bak '/# Workbench/,/export PATH.*\.workbench\/bin/d' "$rc"
    rm -f "$rc.bak"
    printf "${GREEN}✔${RESET}  Cleaned ${CYAN}$rc${RESET}\n"
  fi
done

# Clean up agent directories (skills)
for dir in .agents/skills .cursor/skills .windsurf/skills .kiro/skills; do
  if [ -d "$dir" ]; then
    # Remove workbench skill symlinks/dirs
    for skill in skillify session-extract dream workbench; do
      if [ -e "$dir/$skill" ]; then
        rm -rf "$dir/$skill"
        printf "${GREEN}✔${RESET}  Removed ${CYAN}$dir/$skill${RESET}\n"
      fi
    done
  fi
done

# Clean up Copilot hooks
if [ -d ".github/hooks/copilot" ]; then
  rm -rf ".github/hooks/copilot"
  printf "${GREEN}✔${RESET}  Removed ${CYAN}.github/hooks/copilot/${RESET}\n"
fi

# Clean up steering docs (remove Workbench section)
for file in AGENTS.md .github/copilot-instructions.md .cursorrules .windsurfrules; do
  if [ -f "$file" ] && grep -q "Workbench Memory System" "$file"; then
    # Remove from "## Workbench Memory System" to the next "##" or end of file
    sed -i.bak '/## Workbench Memory System/,/^## [^W]/{ /^## [^W]/!d; }' "$file"
    rm -f "$file.bak"
    printf "${GREEN}✔${RESET}  Cleaned ${CYAN}$file${RESET}\n"
  fi
done

printf "\n${GREEN}✔${RESET}  ${DIM}Uninstall complete${RESET}\n\n"
