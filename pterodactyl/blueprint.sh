```bash
#!/usr/bin/env bash

set -Eeuo pipefail

PURPLE='\033[1;35m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

BASE_URL="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl"

pause() {
    echo
    read -rp "Press Enter to continue..." _ || true
}

header() {
    clear
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}              PRITAM VPS MANAGEMENT TOOLKIT${RESET}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "${CYAN}"
    echo "██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗"
    echo "██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║"
    echo "██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║"
    echo "██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║"
    echo "██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║"
    echo "╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝"
    echo -e "${RESET}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}          BLUEPRINT + THEME + EXTENSIONS${RESET}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

run_remote_script() {
    local filename="$1"
    local tmp
    local status=0

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}curl is not installed. Install curl first.${RESET}"
        return 1
    fi

    tmp="$(mktemp)" || {
        echo -e "${RED}Could not create temporary file.${RESET}"
        return 1
    }

    echo -e "${CYAN}Downloading ${filename}...${RESET}"

    if curl -fsSL --connect-timeout 15 \
        "${BASE_URL}/${filename}" -o "$tmp"; then

        if [ ! -s "$tmp" ]; then
            echo -e "${RED}Downloaded script is empty.${RESET}"
            rm -f "$tmp"
            return 1
        fi

        echo -e "${GREEN}Starting ${filename}...${RESET}"
        bash "$tmp" || status=$?
    else
        echo -e "${RED}Download failed: ${filename}${RESET}"
        status=1
    fi

    rm -f "$tmp"
    return "$status"
}

main_menu() {
    local choice

    while true; do
        header

        echo -e "  ${GREEN}1)${RESET} Blueprint Setup"
        echo -e "  ${GREEN}2)${RESET} Themes + Extensions"
        echo -e "  ${RED}0)${RESET} Back to Main Menu"

        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

        read -rp "📝 Select an option [0-2]: " choice || return 0

        case "$choice" in
            1)
                run_remote_script "blueprint-install.sh" || true
                pause
                ;;
            2)
                themes_menu
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option! Choose 0, 1, or 2.${RESET}"
                pause
                ;;
        esac
    done
}

themes_menu() {
    local choice

    while true; do
        clear

        echo -e "${PURPLE}==============================================${RESET}"
        echo -e "${CYAN}             PRITAM THEMES & TOOLS${RESET}"
        echo -e "${PURPLE}==============================================${RESET}"

        echo -e "${GREEN}1)${RESET} Nebula (Auto Install)"
        echo -e "${GREEN}2)${RESET} Add Tool (Auto Install)"
        echo -e "${RED}0)${RESET} Back to Previous Menu"

        echo -e "${PURPLE}==============================================${RESET}"

        read -rp "Choose an option: " choice || return 0

        case "$choice" in
            1)
                run_remote_script "nebula.sh" || true
                pause
                ;;
            2)
                add_tool_menu
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option!${RESET}"
                pause
                ;;
        esac
    done
}

add_tool_menu() {
    echo
    echo -e "${CYAN}Add Tool${RESET}"
    echo "A verified tool name and installer URL are required."
    echo "No external script has been executed."
    pause
}

main_menu
```
