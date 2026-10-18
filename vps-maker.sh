#!/bin/bash

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED="\e[38;5;196m"
GREEN="\e[38;5;82m"
YELLOW="\e[38;5;226m"
BLUE="\e[38;5;39m"
MAGENTA="\e[38;5;201m"
CYAN="\e[38;5;51m"
WHITE="\e[97m"

BASE_URL="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

print_menu() {
    clear

    echo -e "${CYAN}${BOLD}"
    echo "  ██████  ██████  ██ ████████  █████  ███    ███"
    echo "  ██   ██ ██   ██ ██    ██    ██   ██ ████  ████"
    echo "  ██████  ██████  ██    ██    ███████ ██ ████ ██"
    echo "  ██      ██      ██    ██    ██   ██ ██  ██  ██"
    echo "  ██      ██      ██    ██    ██   ██ ██      ██"
    echo -e "${RESET}"

    echo -e "${CYAN}  ╔══════════════════════════════════════════════════════╗"
    echo -e "  ║${WHITE}${BOLD}                 PRITAM VPS MAKER                     ${CYAN}║"
    echo -e "  ╠══════════════════════════════════════════════════════╣"
    echo -e "  ║                                                      ║"
    echo -e "  ║   ${GREEN}[1]${WHITE}  Create VPS (KVM)                              ${CYAN}║"
    echo -e "  ║   ${YELLOW}[2]${WHITE}  Create VPS (No KVM)                           ${CYAN}║"
    echo -e "  ║   ${RED}[0]${WHITE}  Exit                                           ${CYAN}║"
    echo -e "  ║                                                      ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo
}

run_script() {
    local name="$1"
    local url="${BASE_URL}/${name}"
    local tmp

    tmp="$(mktemp)" || return 1

    echo -e "\n${CYAN}▶ Downloading ${name}...${RESET}"

    if ! curl -fsSL --connect-timeout 10 "$url" -o "$tmp"; then
        echo -e "${RED}❌ Download failed. Check GitHub file: ${name}${RESET}"
        rm -f "$tmp"
        return 1
    fi

    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}❌ Downloaded file is empty.${RESET}"
        rm -f "$tmp"
        return 1
    fi

    bash "$tmp"
    local status=$?
    rm -f "$tmp"
    return "$status"
}

while true; do
    print_menu
    read -rp "$(echo -e "${CYAN}  ➤ Select Option [0-2]: ${RESET}")" choice

    case "$choice" in
        1)
            clear
            echo -e "${GREEN}${BOLD}▶ PRITAM KVM VPS MAKER${RESET}\n"
            run_script "Vm1"
            read -rp $'\nPress Enter to return to menu...'
            ;;
        2)
            clear
            echo -e "${YELLOW}${BOLD}▶ PRITAM NO-KVM VPS MAKER${RESET}\n"
            run_script "Dd" &&
            run_script "Vm2"
            read -rp $'\nPress Enter to return to menu...'
            ;;
        0)
            clear
            echo -e "${MAGENTA}${BOLD}Thanks for using PRITAM VPS MAKER!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option! Please choose 0, 1, or 2.${RESET}"
            sleep 1
            ;;
    esac
done
