
#!/usr/bin/env bash

# ==========================================================
#          JISHNU HOSTING MANAGER
#             made by nobita , jishnu
# ==========================================================

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

BASE="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl"

line() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

menu() {
    clear
    line
    echo -e "${CYAN}           🚀 PRITAM HOSTING MANAGER${RESET}"
    echo -e "${WHITE}                 made by pritam${RESET}"
    line
    echo -e "${PURPLE}"
    cat <<'EOF'
 __  __    _    ___ _   _    __  __ _____ _   _ _   _
|  \/  |  / \  |_ _| \ | |  |  \/  | ____| \ | | | | |
| |\/| | / _ \  | ||  \| |  | |\/| |  _| |  \| | | | |
| |  | |/ ___ \ | || |\  |  | |  | | |___| |\  | |_| |
|_|  |_/_/   \_\___|_| \_|  |_|  |_|_____|_| \_|\___/
EOF
    echo -e "${RESET}"
    line
    echo -e "${GREEN}  1)${WHITE} Panel Installation"
    echo -e "${GREEN}  2)${WHITE} Blueprint Installation"
    echo -e "${GREEN}  3)${WHITE} Blueprint + Theme + Extensions"
    echo -e "${GREEN}  4)${WHITE} Cloudflare Setup"
    echo -e "${GREEN}  5)${WHITE} System Information"
    echo -e "${GREEN}  6)${WHITE} Tailscale (install + up)"
    echo -e "${GREEN}  7)${WHITE} Database Setup"
    echo -e "${RED}  0)${WHITE} Exit"
    line
}

run_script() {
    local file="$1"
    local url="${BASE}/${file}"
    local tmp

    echo
    echo -e "${CYAN}[*] Loading ${file}...${RESET}"

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}[!] curl is not installed.${RESET}"
        read -rp "Press Enter to return..."
        return
    fi

    tmp="$(mktemp)" || return

    if curl -fsSL "$url" -o "$tmp"; then
        bash "$tmp"
        local status=$?
        rm -f "$tmp"

        if [ "$status" -eq 0 ]; then
            echo -e "${GREEN}[✓] Script completed.${RESET}"
        else
            echo -e "${RED}[!] Script exited with code ${status}.${RESET}"
        fi
    else
        rm -f "$tmp"
        echo -e "${RED}[!] Download failed: ${file}${RESET}"
        echo -e "${YELLOW}Check that the file exists on GitHub.${RESET}"
    fi

    echo
    read -rp "Press Enter to return to menu..."
}

while true; do
    menu
    read -rp "$(echo -e "${YELLOW}📝 Select an option [0-7]: ${RESET}")" choice

    case "$choice" in
        1) run_script "pterodactary.sh" ;;
        2) run_script "blueprint-install.sh" ;;
        3) run_script "blueprint.sh" ;;
        4) run_script "cloudflare.sh" ;;
        5) run_script "system-info.sh" ;;
        6) run_script "tailscale.sh" ;;
        7) run_script "database.sh" ;;
        0)
            echo -e "${GREEN}Thanks for using PRITAM HOSTING MANAGER!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option! Choose 0-7.${RESET}"
            sleep 1
            ;;
    esac
done
