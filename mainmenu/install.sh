
#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════
#          PRITAM HOSTING MANAGEMENT TOOLKIT
#                 NEON PROFESSIONAL EDITION
#                     Created by Pritam
# ═══════════════════════════════════════════════════════════

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

BASE="https://raw.githubusercontent.com/PritamYt403"

pause() {
    echo
    read -r -p "  Press Enter to continue..." _ || true
}

line() {
    printf '%b\n' "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

loading() {
    local frames=('◐' '◓' '◑' '◒')
    local i

    for ((i=0; i<12; i++)); do
        printf '\r%b' "  ${PURPLE}${BOLD}${frames[i%4]}${RESET} ${CYAN}Initializing PRITAM HOSTING...${RESET}"
        sleep 0.1
    done

    printf '\r%b\n\n' "  ${GREEN}${BOLD}✔ PRITAM HOSTING READY${RESET}"
}

header() {
    clear 2>/dev/null || true
    echo
    printf '%b\n' "${PURPLE}${BOLD}"

    cat <<'EOF'
    ██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗
    ██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║
    ██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║
    ██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║
    ██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║
    ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
EOF

    printf '%b\n' "${RESET}"
    printf '%b\n' "                  ${ORANGE}${BOLD}P R I T A M${RESET}"
    printf '%b\n' "           ${CYAN}${BOLD}HOSTING MANAGEMENT TOOLKIT${RESET}"
    printf '%b\n' "             ${PINK}✦ NEON PROFESSIONAL EDITION ✦${RESET}"
    printf '%b\n' "                 ${GRAY}Made by Pritam${RESET}"
    line
    echo
}

run_command() {
    local url="$1"
    local script
    local status

    script="$(mktemp)" || {
        printf '%b\n' "  ${RED}Cannot create temporary file.${RESET}"
        pause
        return 1
    }

    echo
    line
    printf '%b\n' "  ${CYAN}${BOLD}➤ LAUNCHING SERVICE${RESET}"
    printf '%b\n' "  ${GRAY}Downloading script...${RESET}"
    line

    if ! curl -fsSL --connect-timeout 10 --max-time 120 "$url" -o "$script"; then
        printf '\n%b\n' "  ${RED}${BOLD}✘ DOWNLOAD FAILED${RESET}"
        printf '%b\n' "  ${YELLOW}Check the repository and file path.${RESET}"
        rm -f "$script"
        pause
        return 1
    fi

    if [[ ! -s "$script" ]] || ! bash -n "$script"; then
        printf '\n%b\n' "  ${RED}${BOLD}✘ Invalid script or Bash syntax error.${RESET}"
        rm -f "$script"
        pause
        return 1
    fi

    printf '%b\n\n' "  ${GREEN}✔ Script syntax verified.${RESET}"

    bash "$script"
    status=$?
    rm -f "$script"

    if (( status == 0 )); then
        printf '\n%b\n' "  ${GREEN}✔ Service finished.${RESET}"
    else
        printf '\n%b\n' "  ${YELLOW}⚠ Service exited with code ${status}.${RESET}"
    fi

    pause
}

coming_soon() {
    local frames=('◐' '◓' '◑' '◒')
    local i

    echo
    line
    echo

    for ((i=0; i<20; i++)); do
        printf '\r%b' "  ${ORANGE}${BOLD}${frames[i%4]} ${WHITE}COMING SOON${ORANGE} - Preparing something awesome...${RESET}"
        sleep 0.12
    done

    echo
    echo
    printf '%b\n' "  ${PINK}${BOLD}✦ SYSTEM EDIT ✦${RESET}"
    printf '%b\n' "  ${CYAN}This feature is currently under development.${RESET}"
    printf '%b\n' "  ${YELLOW}Please check back later!${RESET}"
    echo
    line
    pause
}

main_menu() {
    local choice

    while true; do
        header

        printf '%b\n' "  ${WHITE}${BOLD}╭──────────────── MAIN MENU ────────────────╮${RESET}"
        printf '%b\n' "  ${PURPLE}${BOLD}  [A]${RESET} ${WHITE}Pterodactyl Management${RESET}"
        printf '%b\n' "  ${CYAN}${BOLD}  [B]${RESET} ${WHITE}VPS Maker${RESET}"
        printf '%b\n' "  ${ORANGE}${BOLD}  [C]${RESET} ${YELLOW}System Edit ${GRAY}(COMING SOON)${RESET}"
        printf '%b\n' "  ${RED}${BOLD}  [D]${RESET} ${WHITE}Exit Toolkit${RESET}"
        printf '%b\n' "  ${WHITE}${BOLD}╰────────────────────────────────────────────╯${RESET}"
        echo

        read -r -p "$(printf '%b' "${PINK}${BOLD}  PRITAM ${CYAN}» ${RESET}")" choice || exit 0

        case "$choice" in
            A|a)
                run_command "${BASE}/hosting/main/pterodactyl/install.sh"
                ;;
            B|b)
                run_command "${BASE}/hosting/main/mainmenu/vps-maker.sh"
                ;;
            C|c)
                coming_soon
                ;;
            D|d)
                echo
                line
                printf '%b\n' "  ${PINK}${BOLD}Thank you for using PRITAM HOSTING!${RESET}"
                printf '%b\n' "  ${CYAN}Made by Pritam. Goodbye!${RESET}"
                line
                exit 0
                ;;
            *)
                printf '\n%b\n' "  ${RED}✘ Invalid option! Choose A, B, C or D.${RESET}"
                sleep 1
                ;;
        esac
    done
}

if ! command -v curl >/dev/null 2>&1; then
    printf '%b\n' "${RED}curl is required.${RESET}"
    echo "Install: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

loading
main_menu
