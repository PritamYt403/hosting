#!/bin/bash

# ==========================================
# COLOR & STYLE DEFINITIONS
# ==========================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# ==========================================
# UI FUNCTIONS
# ==========================================

print_menu() {
    clear
    # ASCII Banner
    echo -e "${GREEN}${BOLD}"
    echo -e "  ██████  ██████  ██ ████████  █████  ███    ███"
    echo -e "  ██   ██ ██   ██ ██    ██    ██   ██ ████  ████"
    echo -e "  ██████  ██████  ██    ██    ███████ ██ ████ ██"
    echo -e "  ██      ██      ██    ██    ██   ██ ██  ██  ██"
    echo -e "  ██      ██      ██    ██    ██   ██ ██      ██"
    echo -e "${RESET}\n"

    # Main Menu Box
    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}  │${BOLD}${WHITE}                 P R I T A M   V P S                  ${CYAN}│${RESET}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  │   ${YELLOW}[1]${RESET} Run Virtual Machine Installer (KVM)            ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${BLUE}[2]${RESET} Run Virtual Machine Installer (No KVM)         ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${RED}[0]${RESET} Exit                                           ${CYAN}│${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
    echo -e ""
}

print_status() {
    local text="$1"
    local color="$2"
    echo -e "\n  ${color}${BOLD}▶ ${text}${RESET}\n"
}

print_divider() {
    echo -e "  ${DIM}────────────────────────────────────────────────────────${RESET}"
}

# ==========================================
# MAIN LOOP
# ==========================================

while true; do
    print_menu

    echo -ne "  ${CY
