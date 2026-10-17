
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

main_menu() {
    while true; do
        header
        echo -e "  ${GREEN}1)${RESET} Blueprint Setup"
        echo -e "  ${GREEN}2)${RESET} Themes + Extensions"
        echo -e "  ${RED}0)${RESET} Back to Main Menu"
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

        read -rp "📝 Select an option [0-2]: " choice || return 0

        case "$choice" in
            1) blueprint_setup ;;
            2) themes_menu ;;
            0) return 0 ;;
            *)
                echo -e "${RED}Invalid option! Choose 0, 1, or 2.${RESET}"
                pause
                ;;
        esac
    done
}

blueprint_setup() {
    clear
    echo -e "${PURPLE}==============================================${RESET}"
    echo -e "${CYAN}             PRITAM BLUEPRINT SETUP${RESET}"
    echo -e "${PURPLE}==============================================${RESET}"
    echo
    echo -e "${YELLOW}Blueprint installer URL is not configured yet.${RESET}"
    echo "Configure a verified official installer URL before installation."
    pause
}

themes_menu() {
    while true; do
        clear
        echo -e "${PURPLE}==============================================${RESET}"
        echo -e "${CYAN}             PRITAM THEMES & TOOLS${RESET}"
        echo -e "${PURPLE}==============================================${RESET}"
        echo -e "${GREEN}1)${RESET} Nebula (Auto Install)"
        echo -e "${GREEN}2)${RESET} Euphoria (Auto Install)"
        echo -e "${YELLOW}3)${RESET} Uninstall"
        echo -e "${GREEN}4)${RESET} Add Tool (Auto Install)"
        echo -e "${RED}0)${RESET} Back to Previous Menu"
        echo -e "${PURPLE}==============================================${RESET}"

        read -rp "Choose an option: " choice || return 0

        case "$choice" in
            1) installer_notice "Nebula" ;;
            2) installer_notice "Euphoria" ;;
            3) uninstall_menu ;;
            4) add_tool_menu ;;
            0) return 0 ;;
            *)
                echo -e "${RED}Invalid option!${RESET}"
                pause
                ;;
        esac
    done
}

installer_notice() {
    local name="$1"
    echo
    echo -e "${CYAN}${name} Auto Installer${RESET}"
    echo -e "${YELLOW}The official installer URL has not been configured.${RESET}"
    echo "No changes have been made to your server."
    pause
}

uninstall_menu() {
    echo
    echo -e "${YELLOW}Uninstall${RESET}"
    echo "The uninstall routine is not configured yet."
    echo "No files or services have been removed."
    pause
}

add_tool_menu() {
    echo
    echo -e "${CYAN}Add Tool${RESET}"
    echo "A verified tool name and installer URL are required."
    echo "No external script has been executed."
    pause
}

main_menu
