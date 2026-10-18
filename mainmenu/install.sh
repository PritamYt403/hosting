#!/usr/bin/env bash

# ==========================================
# PRITAM HOSTING MANAGEMENT TOOLKIT
# NEON PROFESSIONAL MAIN MENU
# Created by Pritam
# ==========================================

BASE="https://raw.githubusercontent.com/PritamYt403/hosting/main"

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

clear

line() {
    printf "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

header() {
    clear
    line
    printf "${CYAN}${BOLD}       PRITAM HOSTING MANAGEMENT TOOLKIT${RESET}\n"
    printf "${GRAY}             NEON PROFESSIONAL EDITION${RESET}\n"
    line
    echo
}

loading() {
    printf "${CYAN}Starting toolkit"
    for i in 1 2 3; do
        printf "."
        sleep 0.25
    done
    printf "${GREEN} Ready!${RESET}\n"
    sleep 0.3
}

pause() {
    echo
    read -rp "Press Enter to continue..."
}

run_command() {
    local url="$1"
    local tmp

    tmp=$(mktemp) || {
        echo -e "${RED}Unable to create temporary file.${RESET}"
        pause
        return
    }

    echo
    echo -e "${CYAN}Downloading script...${RESET}"

    if ! curl -fLsS "$url" -o "$tmp"; then
        echo -e "${RED}Download failed. Check the GitHub file path.${RESET}"
        rm -f "$tmp"
        pause
        return
    fi

    if [[ ! -s "$tmp" ]] || ! bash -n "$tmp"; then
        echo -e "${RED}Script is empty or contains a syntax error.${RESET}"
        rm -f "$tmp"
        pause
        return
    fi

    echo -e "${GREEN}Launching script...${RESET}"
    bash "$tmp"
    local status=$?

    rm -f "$tmp"

    if [[ $status -ne 0 ]]; then
        echo -e "${RED}Script exited with error code: $status${RESET}"
    fi

    pause
}

main_menu() {
    while true; do
        header

        printf " ${GREEN}[1]${RESET} Pterodactyl Management\n"
        printf " ${YELLOW}[2]${RESET} VPS Maker ${GRAY}(Coming Soon)${RESET}\n"
        printf " ${CYAN}[3]${RESET} System Information ${GRAY}(Coming Soon)${RESET}\n"
        printf " ${RED}[0]${RESET} Exit\n"

        echo
        line
        read -rp " Select option [0-3]: " choice

        case "$choice" in
            1)
                run_command "${BASE}/pterodactyl/install.sh"
                ;;
            2|3)
                echo
                echo -e "${YELLOW}This feature will be connected later.${RESET}"
                pause
                ;;
            0)
                echo
                echo -e "${GREEN}Thank you for using Pritam Hosting Toolkit!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option! Try again.${RESET}"
                sleep 1
                ;;
        esac
    done
}

loading
main_menu
