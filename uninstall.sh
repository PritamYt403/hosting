
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
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}          🗑️ PRITAM PTERODACTYL UNINSTALLER${RESET}"
    echo -e "${WHITE}                     by PRITAM${RESET}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                📋 MENU OPTIONS                ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo "║  1) Uninstall Panel Only                      ║"
    echo "║  2) Uninstall Wings Only                      ║"
    echo "║  3) Uninstall Panel + Wings                   ║"
    echo "║  0) Exit Uninstaller                          ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo
    echo -e "${RED}⚠ WARNING: Uninstalling may remove services and data.${RESET}"
    echo
}

confirm_action() {
    local description="$1"
    local answer

    echo
    echo -e "${YELLOW}Selected: ${description}${RESET}"
    echo "Back up your server before proceeding."
    read -rp "Type YES to confirm: " answer || return 1

    [[ "$answer" == "YES" ]]
}

uninstall_panel() {
    echo
    echo -e "${CYAN}Panel uninstall selected.${RESET}"
    echo "This script does not yet have a verified Panel removal routine."
    echo -e "${YELLOW}No Panel files or services have been removed.${RESET}"
    pause
}

uninstall_wings() {
    echo
    echo -e "${CYAN}Wings uninstall selected.${RESET}"
    echo "This script does not yet have a verified Wings removal routine."
    echo -e "${YELLOW}No Wings files or services have been removed.${RESET}"
    pause
}

uninstall_both() {
    echo
    echo -e "${CYAN}Panel + Wings uninstall selected.${RESET}"
    echo "This script does not yet have a verified removal routine."
    echo -e "${YELLOW}No Panel or Wings files or services have been removed.${RESET}"
    pause
}

main() {
    while true; do
        header
        read -rp "Choose an option [0-3]: " choice || return 0

        case "$choice" in
            1)
                if confirm_action "Uninstall Panel Only"; then
                    uninstall_panel
                else
                    echo -e "${GREEN}Cancelled. Nothing was removed.${RESET}"
                    pause
                fi
                ;;
            2)
                if confirm_action "Uninstall Wings Only"; then
                    uninstall_wings
                else
                    echo -e "${GREEN}Cancelled. Nothing was removed.${RESET}"
                    pause
                fi
                ;;
            3)
                if confirm_action "Uninstall Panel + Wings"; then
                    uninstall_both
                else
                    echo -e "${GREEN}Cancelled. Nothing was removed.${RESET}"
                    pause
                fi
                ;;
            0)
                echo -e "${GREEN}Returning to the previous menu...${RESET}"
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option. Choose 0, 1, 2, or 3.${RESET}"
                pause
                ;;
        esac
    done
}

main "$@"
