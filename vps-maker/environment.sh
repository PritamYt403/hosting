#!/usr/bin/env bash

# ==========================================
# PRITAM HOSTING - DEVELOPMENT MENU V26.1
# ==========================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

BASE="https://raw.githubusercontent.com/PritamYt403/hosting/main/vps-maker"

print_menu() {
    clear
    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮"
    echo -e "  │${WHITE}${BOLD}        D E V E L O P M E N T   M E N U  (V26.1)      ${CYAN}│"
    echo -e "  ├──────────────────────────────────────────────────────┤"
    echo -e "  │                                                      │"
    echo -e "  │   ${GREEN}[1]${RESET} Environment Tool                               ${CYAN}│"
    echo -e "  │   ${YELLOW}[2]${RESET} Run Virtual Machine Installer (KVM)            ${CYAN}│"
    echo -e "  │   ${BLUE}[3]${RESET} Run Virtual Machine Installer (No KVM)         ${CYAN}│"
    echo -e "  │   ${MAGENTA}[4]${RESET} Proxmox Setup                                  ${CYAN}│"
    echo -e "  │   ${RED}[5]${RESET} Exit                                           ${CYAN}│"
    echo -e "  │                                                      │"
    echo -e "  ╰──────────────────────────────────────────────────────╯${RESET}"
    echo
}

print_status() {
    echo -e "\n  ${2}${BOLD}▶ $1${RESET}\n"
}

pause_menu() {
    echo
    read -r -p "  ↩ Press Enter to return..."
}

run_script() {
    local script="$1"
    local url="${BASE}/${script}"
    local tmp

    tmp="$(mktemp)" || {
        echo -e "${RED}Could not create temporary file.${RESET}"
        return 1
    }

    echo -e "${CYAN}  📡 Downloading ${script}...${RESET}"

    if ! curl -fLsS "$url" -o "$tmp"; then
        echo -e "${RED}❌ Download failed: ${script}${RESET}"
        rm -f "$tmp"
        return 1
    fi

    bash "$tmp"
    local result=$?
    rm -f "$tmp"

    if [ "$result" -ne 0 ]; then
        echo -e "${RED}⚠ Script exited with an error.${RESET}"
    fi

    return "$result"
}

while true; do
    print_menu
    read -r -p "$(echo -e "  ${CYAN}▶${RESET} ${BOLD}Select Option: ${RESET}")" op

    case "$op" in
        1)
            clear
            print_status "Running Your Environment Setup..." "$GREEN"
            run_script "environment.sh"
            pause_menu
            ;;

        2)
            clear
            print_status "Starting KVM Virtual Machine Installer..." "$YELLOW"
            run_script "vm-kvm.sh"
            pause_menu
            ;;

        3)
            clear
            print_status "Starting No-KVM Virtual Machine Installer..." "$BLUE"
            run_script "vm-nokvm.sh"
            pause_menu
            ;;

        4)
            clear
            print_status "Starting Proxmox Setup..." "$MAGENTA"
            run_script "proxmox.sh"
            pause_menu
            ;;

        5)
            clear
            echo -e "${CYAN}  ╭──────────────────────────────────────────────╮"
            echo -e "  │${WHITE}${BOLD}                  EXITING                       ${CYAN}│"
            echo -e "  ╰──────────────────────────────────────────────╯${RESET}"
            echo -e "\n  ${YELLOW}Thank you for using PRITAM HOSTING!${RESET}\n"
            exit 0
            ;;

        *)
            echo -e "\n  ${RED}❌ Invalid option! Please try again.${RESET}"
            sleep 1
            ;;
    esac
done
