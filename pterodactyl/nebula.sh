
#!/usr/bin/env bash

# ==========================================
#       PRITAM NEBULA THEME INSTALLER
# ==========================================

set -Eeuo pipefail

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

PANEL_DIR="/var/www/pterodactyl"
THEME_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/Theme/main/Ex/nebula.blueprint"
THEME_FILE="nebula.blueprint"

echo -e "${PURPLE}============================================${NC}"
echo -e "${CYAN}       PRITAM NEBULA THEME INSTALLER${NC}"
echo -e "${PURPLE}============================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root.${NC}"
    exit 1
fi

if [ ! -f "$PANEL_DIR/blueprint.sh" ]; then
    echo -e "${RED}Blueprint/Pterodactyl installation not found.${NC}"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is not installed.${NC}"
    exit 1
fi

if ! command -v blueprint >/dev/null 2>&1; then
    echo -e "${RED}Blueprint command not found.${NC}"
    exit 1
fi

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

echo -e "${YELLOW}Downloading Nebula theme...${NC}"

if ! curl -fLsS "$THEME_URL" -o "$TEMP_FILE"; then
    echo -e "${RED}Theme download failed.${NC}"
    exit 1
fi

if [ ! -s "$TEMP_FILE" ]; then
    echo -e "${RED}Downloaded theme file is empty.${NC}"
    exit 1
fi

install -m 0644 "$TEMP_FILE" "$PANEL_DIR/$THEME_FILE"

cd "$PANEL_DIR"

echo -e "${YELLOW}Installing PRITAM Nebula theme...${NC}"

if blueprint -install nebula; then
    echo -e "${GREEN}Nebula theme installation completed!${NC}"
else
    echo -e "${RED}Nebula installation failed. Check Blueprint output.${NC}"
    exit 1
fi
