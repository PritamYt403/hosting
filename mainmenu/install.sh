
#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════
#          PRITAM HOSTING MANAGEMENT TOOLKIT
#                   NEON PROFESSIONAL
# ═══════════════════════════════════════════════════════

set -o pipefail

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
    printf "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

loading() {
    local frames=('◐' '◓' '◑' '◒')
    local i

    printf "\n  ${CYAN}${BOLD}Initializing PRITAM HOSTING${RESET} "

    for ((i=0; i<12; i++)); do
        printf "\r  ${PURPLE}${BOLD}${frames[i%4]}${RESET} ${CYAN}Initializing PRITAM HOSTING...${RESET}"
        sleep 0.10
    done

    printf "\r  ${GREEN}${BOLD}✔ PRITAM HOSTING READY                         ${RESET}\n\n"
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
    echo -e "          ${PINK}✦ NEON PROFESSIONAL EDITION ✦${RESET}"
    echo -e "                ${GRAY}Created by Pritam${RESET}"

    line
    echo
}

run_command() {
    local url="$1"
    local script
    local status

    script="$(mktemp)" || {
        echo -e "${RED}  ✘ Cannot create temporary file.${RESET}"
        pause
        return 1
    }

    echo
    line
    echo -e "  ${CYAN}${BOLD}➤ LAUNCHING SERVICE${RESET}"
    echo -e "  ${GRAY}Downloading selected script...${RESET}"
    line

    if ! curl -fsSL --connect-timeout 10 --max-time 120 "$url" -o "$script"; then
        echo -e "\n  ${RED}${BOLD}✘ DOWNLOAD FAILED${RESET}"
        echo -e "  ${YELLOW}Check the URL or internet connection.${RESET}"
        rm -f "$script"
        pause
        return 1
    fi

    if [[ ! -s "$script" ]] || ! bash -n "$script"; then
        echo -e "\n  ${RED}${BOLD}✘ Invalid script or Bash syntax error.${RESET}"
        rm -f "$script"
        pause
        return 1
    fi

    echo -e "  ${GREEN}✔ Script downloaded and syntax checked.${RESET}"
    echo

    bash "$script"
    status=$?

    rm -f "$script"

    if (( status == 0 )); then
        echo -e "\n  ${GREEN}${BOLD}✔ SERVICE FINISHED${RESET}"
    else
        echo -e "\n  ${YELLOW}${BOLD}⚠ SERVICE EXITED WITH CODE ${status}${RESET}"
    fi

    pause
}

main_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭──────────────── MAIN MENU ────────────────╮${RESET}"
        echo -e "  ${PURPLE}${BOLD}  [A]${RESET} ${WHITE}Pterodactyl Management${RESET}"
        echo -e "  ${CYAN}${BOLD}  [B]${RESET} ${WHITE}VPS Maker${RESET}"
        echo -e "  ${GREEN}${BOLD}  [C]${RESET} ${WHITE}Tools & Utilities${RESET}"
        echo -e "  ${ORANGE}${BOLD}  [D]${RESET} ${WHITE}System Edit${RESET}"
        echo -e "  ${RED}${BOLD}  [E]${RESET} ${WHITE}Exit Toolkit${RESET}"
        echo -e "  ${WHITE}${BOLD}╰────────────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}${BOLD}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            A|a)
                run_command "${REPO}/pterodactyl/main/install.sh"
                ;;
            B|b)
                run_command "${REPO}/hosting/main/mainmanu/vps-maker.sh"
                ;;
            C|c)
                run_command "${REPO}/hosting/main/mainmanu/tools.sh"
                ;;
            D|d)
                run_command "${REPO}/hosting/main/mainmanu/system-edit.sh"
                ;;
            E|e)
                echo
                line
                echo -e "  ${PINK}${BOLD}✦ THANK YOU FOR USING PRITAM HOSTING ✦${RESET}"
                echo -e "  ${CYAN}          Made with care by Pritam${RESET}"
                line
                exit 0
                ;;
            *)
                echo -e "\n  ${RED}✘ Invalid option! Choose A, B, C, D or E.${RESET}"
                sleep 1
                ;;
        esac
    done
}

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is required.${RESET}"
    echo "Install: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

loading
main_menu
