
#!/usr/bin/env bash

# ==========================================
#       PTERODACTYL CONTROL CENTER
# ==========================================

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

line() {
    echo -e "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

run_script() {
    local file="$1"
    local url="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl/${file}"
    local tmp

    tmp="$(mktemp)" || return

    echo -e "${CYAN}[*] Loading ${file}...${RESET}"

    if curl -fsSL "$url" -o "$tmp"; then
        bash "$tmp"
        local status=$?
        rm -f "$tmp"
        echo
        if [ "$status" -ne 0 ]; then
            echo -e "${RED}[!] Script exited with code ${status}.${RESET}"
        fi
    else
        rm -f "$tmp"
        echo -e "${RED}[!] Could not download ${file}${RESET}"
    fi

    echo
    read -rp "Press Enter to return..."
}

while true; do
    clear

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}║        ⚡ PTERODACTYL CONTROL CENTER                         ║${RESET}"
    echo -e "${CYAN}║        Professional Server Management System                 ║${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

    echo
    line
    echo -e "${YELLOW}  CONTROL MODULES${RESET}"
    line
    echo
    echo -e "  ${GREEN}[1]${WHITE} Panel Installation${RESET}"
    echo -e "      Fresh Pterodactyl Panel Installation"
    echo
    echo -e "  ${GREEN}[2]${WHITE} Account Management${RESET}"
    echo -e "      Create Admin / User Accounts"
    echo
    echo -e "  ${GREEN}[3]${WHITE} Panel Update${RESET}"
    echo -e "      Update to a Pterodactyl Release"
    echo
    echo -e "  ${GREEN}[4]${WHITE} Panel Removal${RESET}"
    echo -e "      Remove Panel Data and Configuration"
    echo
    echo -e "${PURPLE}  ──────────────────────────────────────────────────────────${RESET}"
    echo
    echo -e "  ${RED}[0]${WHITE} Exit System${RESET}"
    echo
    line

    read -rp "$(echo -e "${YELLOW}  Select an option: ${RESET}")" choice

    case "$choice" in
        1) run_script "pterodactary.sh" ;;
        2) run_script "user-management.sh" ;;
        3) run_script "panel-update.sh" ;;
        5)
            echo
            echo -e "${RED}WARNING: Panel removal can delete important data.${RESET}"
            read -rp "Type YES to continue: " confirm
            if [[ "$confirm" == "YES" ]]; then
                run_script "uninstall.sh"
            else
                echo -e "${YELLOW}Cancelled.${RESET}"
                sleep 1
            fi
            ;;
        0)
            echo -e "${GREEN}Exiting Control Center...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${RESET}"
            sleep 1
            ;;
    esac
done
