
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

panel_status() {
    if [[ -f /var/www/pterodactyl/artisan ]]; then
        printf '%b' "${GREEN}INSTALLED ✓${RESET}"
    else
        printf '%b' "${RED}NOT INSTALLED ✘${RESET}"
    fi
}

header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}║${RESET}                                                              ${PURPLE}║${RESET}"
    echo -e "${PURPLE}║${RESET}        ${CYAN}⚡ PRITAM PTERODACTYL CONTROL CENTER${RESET}             ${PURPLE}║${RESET}"
    echo -e "${PURPLE}║${RESET}        ${WHITE}Professional Server Management System${RESET}          ${PURPLE}║${RESET}"
    echo -e "${PURPLE}║${RESET}                                                              ${PURPLE}║${RESET}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${RESET}"
    printf "║  PANEL STATUS : "
    panel_status
    echo -e "                               ${PURPLE}║${RESET}"
    echo -e "${PURPLE}║  CREDITS      : PRITAM                                      ║${RESET}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${WHITE}CONTROL MODULES${RESET}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "  ${GREEN}[1]${RESET} Install Panel"
    echo "      Fresh Pterodactyl Panel Installation"
    echo
    echo -e "  ${GREEN}[2]${RESET} User Management"
    echo "      Create Admin / User Accounts"
    echo
    echo -e "  ${GREEN}[3]${RESET} Panel Update"
    echo "      Update to a Pterodactyl Release"
    echo
    echo -e "  ${GREEN}[4]${RESET} Domain / SSL"
    echo "      Configure Domain and SSL"
    echo
    echo -e "  ${RED}[5]${RESET} Uninstall Panel"
    echo "      Remove Panel Data and Configuration"
    echo
    echo -e "  ${GREEN}[6]${RESET} phpMyAdmin"
    echo "      Database Management"
    echo
    echo -e "  ${CYAN}  ──────────────────────────────────────────────────────────${RESET}"
    echo
    echo -e "  ${RED}[0]${RESET} Exit System"
    echo
}

not_configured() {
    local name="$1"
    echo
    echo -e "${YELLOW}${name} module is not connected yet.${RESET}"
    echo "No server changes have been made."
    pause
}

install_panel() {
    echo
    echo -e "${YELLOW}Panel installation needs an OS and dependency check first.${RESET}"
    echo "Use the official Pterodactyl installation documentation:"
    echo "https://pterodactyl.io/panel/1.0/getting_started.html"
    pause
}

main() {
    while true; do
        header
        read -rp "  root@pritam:~# " choice || return 0

        case "$choice" in
            1) install_panel ;;
            2) not_configured "User Management" ;;
            3) not_configured "Panel Update" ;;
            4) not_configured "Domain / SSL" ;;
            5) not_configured "Panel Uninstall" ;;
            6) not_configured "phpMyAdmin" ;;
            0)
                echo -e "${GREEN}Returning to the main menu...${RESET}"
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option. Choose 0-6.${RESET}"
                pause
                ;;
        esac
    done
}

main "$@"
