#!/usr/bin/env bash

# ==========================================================
#       PRITAM HOSTING MANAGER - PANEL + WINGS
#                  made by pritam
# ==========================================================

set -u

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

line() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

pause_menu() {
    echo
    read -r -p "Press Enter to return..." _ || true
}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo -e "${RED}[!] Run this script as root (sudo -i).${RESET}"
    pause_menu
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}[!] curl is required. Install curl and retry.${RESET}"
    pause_menu
    exit 1
fi

clear
line
echo -e "${CYAN}       PANEL + WINGS INSTALLATION${RESET}"
line
echo -e "${YELLOW}This starts the Pterodactyl installer menu.${RESET}"
echo -e "${YELLOW}Choose the Panel and/or Wings options in that menu.${RESET}"
echo -e "${RED}Only continue if you trust the installer source.${RESET}"
read -r -p "Continue? Type YES: " confirm

if [[ "$confirm" != "YES" ]]; then
    echo -e "${YELLOW}Cancelled.${RESET}"
    pause_menu
    exit 0
fi

tmp="$(mktemp)" || {
    echo -e "${RED}[!] Could not create a temporary file.${RESET}"
    pause_menu
    exit 1
}

cleanup() {
    rm -f "$tmp"
}
trap cleanup EXIT

echo -e "${CYAN}[*] Downloading installer...${RESET}"
if ! curl -fsSL --connect-timeout 20 --retry 2 \
    "https://pterodactyl-installer.se" -o "$tmp" || [[ ! -s "$tmp" ]]; then
    echo -e "${RED}[!] Download failed. Check the URL and internet connection.${RESET}"
    pause_menu
    exit 1
fi

echo -e "${CYAN}[*] Starting installer...${RESET}"
bash "$tmp"
status=$?

if [[ "$status" -eq 0 ]]; then
    echo -e "${GREEN}[✓] Installer finished.${RESET}"
else
    echo -e "${RED}[!] Installer exited with code ${status}.${RESET}"
fi

pause_menu
exit "$status"
