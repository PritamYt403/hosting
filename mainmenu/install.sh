
#!/usr/bin/env bash

# ═════════════════════════════════════════════════════
#          PRITAM HOSTING MANAGEMENT TOOLKIT
#                  Professional Edition
# ═════════════════════════════════════════════════════

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
ORANGE='\033[38;5;208m'
PINK='\033[38;5;213m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
RESET='\033[0m'
BOLD='\033[1m'

REPO="https://raw.githubusercontent.com/PritamYt403"

pause() {
    echo
    read -rp "  Press Enter to continue..." _
}

line() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

run_command() {
    local url="$1"

    echo
    line
    echo -e "${CYAN}${BOLD}  Starting selected service...${RESET}"
    line
    echo

    if ! bash <(curl -fsSL --connect-timeout 10 "$url"); then
        echo
        echo -e "${RED}  [ERROR] Command failed!${RESET}"
        echo -e "${YELLOW}  Check the URL and internet connection.${RESET}"
    fi

    pause
}

header() {
    clear 2>/dev/null || true
    echo
    echo -e "${PURPLE}${BOLD}"
    cat <<'EOF'
    ██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗
    ██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║
    ██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║
    ██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║
    ██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║
    ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "             ${ORANGE}${BOLD}P R I T A M${RESET}"
    echo -e "       ${CYAN}${BOLD}HOSTING MANAGEMENT TOOLKIT${RESET}"
    echo -e "             ${PINK}Professional Edition${RESET}"
    echo -e "                ${GRAY}Made by Pritam${RESET}"
    line
    echo
}

main_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭────────────── MAIN MENU ──────────────╮${RESET}"
        echo -e "  ${PURPLE} [A]${RESET} ${WHITE}Pterodactyl Management${RESET}"
        echo -e "  ${CYAN} [B]${RESET} ${WHITE}VPS Maker${RESET}"
        echo -e "  ${GREEN} [C]${RESET} ${WHITE}Tools & Utilities${RESET}"
        echo -e "  ${ORANGE}[D]${RESET} ${WHITE}System Edit${RESET}"
        echo -e "  ${RED} [E]${RESET} ${WHITE}Exit Toolkit${RESET}"
        echo -e "  ${WHITE}${BOLD}╰──────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            A|a)
                run_command \
                    "${REPO}/pterodactyl/main/install.sh"
                ;;
            B|b)
                run_command \
                    "${REPO}/hosting/main/mainmanu/vps-maker.sh"
                ;;
            C|c)
                run_command \
                    "${REPO}/hosting/main/mainmanu/tools.sh"
                ;;
            D|d)
                run_command \
                    "${REPO}/hosting/main/mainmanu/system-edit.sh"
                ;;
            E|e)
                echo
                line
                echo -e "${PINK}${BOLD}  Thank you for using PRITAM!${RESET}"
                echo -e "${CYAN}  Made by Pritam. Goodbye!${RESET}"
                line
                exit 0
                ;;
            *)
                echo -e "${RED}  Invalid option! Choose A-E.${RESET}"
                sleep 1
                ;;
        esac
    done
}

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is required to run this toolkit.${RESET}"
    echo "Install: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

main_menu
