
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

BASE_URL="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl"

line() {
    echo -e "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

run_script() {
    local file="$1"
    local tmp
    local status=0

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}[!] curl is not installed.${RESET}"
        return 1
    fi

    tmp="$(mktemp)" || return 1

    echo -e "${CYAN}[*] Downloading ${file}...${RESET}"

    if curl -fsSL --connect-timeout 15 "${BASE_URL}/${file}" -o "$tmp"; then
        if [[ ! -s "$tmp" ]]; then
            echo -e "${RED}[!] Downloaded file is empty.${RESET}"
            rm -f "$tmp"
            return 1
        fi

        echo -e "${GREEN}[*] Running ${file}...${RESET}"
        bash "$tmp" || status=$?
    else
        echo -e "${RED}[!] Could not download ${file}.${RESET}"
        status=1
    fi

    rm -f "$tmp"

    if [[ "$status" -ne 0 ]]; then
        echo -e "${RED}[!] Script exited with code ${status}.${RESET}"
    fi

    echo
    read -rp "Press Enter to return..." _ || true
    return 0
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

    echo -e "  ${RED}[2]${WHITE} Panel Removal${RESET}"
    echo -e "      Remove Panel Data and Configuration"
    echo

    echo -e "  ${RED}[0]${WHITE} Exit System${RESET}"
    echo
    line

    read -rp "$(echo -e "${YELLOW}  Select an option [0-2]: ${RESET}")" choice || exit 0

    case "$choice" in
        1)
            run_script "pterodactary.sh"
            ;;
        2)
            echo
            echo -e "${RED}WARNING: Panel removal may delete panel data and configuration!${RESET}"
            read -rp "Type YES to confirm removal: " confirm

            if [[ "$confirm" == "YES" ]]; then
                run_script "uninstall.sh"
            else
                echo -e "${YELLOW}Removal cancelled.${RESET}"
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
