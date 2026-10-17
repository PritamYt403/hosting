
#!/usr/bin/env bash

# ═════════════════════════════════════════════════════
#             PRITAM VPS MANAGEMENT TOOLKIT
#                  Professional Edition
# ═════════════════════════════════════════════════════

set -o pipefail

BASE="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

PURPLE='\033[1;35m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
ORANGE='\033[38;5;208m'
PINK='\033[38;5;213m'
RESET='\033[0m'
BOLD='\033[1m'

pause() {
    echo
    read -rp "  Press Enter to continue..." _
}

loading() {
    printf "\n  ${PURPLE}${BOLD}Initializing"
    for _ in 1 2 3 4 5; do
        printf "${CYAN} ◆"
        sleep 0.10
    done
    printf "${RESET}\n\n"
}

line() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
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

    echo -e "        ${ORANGE}${BOLD}P R I T A M${RESET}"
    echo -e "     ${CYAN}${BOLD}VPS MANAGEMENT TOOLKIT${RESET}"
    echo -e "        ${PINK}Made by Pritam${RESET}"
    line
    echo
}

run_module() {
    local file="$1"
    local tmp
    local url="${BASE}/${file}"
    local result=0

    tmp="$(mktemp)" || {
        echo -e "${RED}  [ERROR] Cannot create temporary file.${RESET}"
        pause
        return 1
    }

    echo
    echo -e "${CYAN}  ◈ MODULE  ${WHITE}${BOLD}${file}${RESET}"
    echo -e "${GRAY}  Downloading latest version from GitHub...${RESET}"

    if ! curl -fsSL --connect-timeout 10 --max-time 60 \
        "$url" -o "$tmp"; then
        echo -e "${RED}  ✗ Download failed: ${file}${RESET}"
        echo -e "${YELLOW}  Check the filename and GitHub main branch.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    if [[ ! -s "$tmp" ]] || ! bash -n "$tmp"; then
        echo -e "${RED}  ✗ Empty file or Bash syntax error.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    echo -e "${GREEN}  ✓ Script verified successfully.${RESET}"
    echo -e "${GRAY}  ──────────────────────────────────────────────────${RESET}"
    echo

    bash "$tmp" || result=$?
    rm -f "$tmp"

    echo
    if (( result == 0 )); then
        echo -e "${GREEN}  ✓ Module completed.${RESET}"
    else
        echo -e "${YELLOW}  ! Module exited with code ${result}.${RESET}"
    fi

    pause
    return "$result"
}

run_system_info() {
    run_module "system-info.sh"
}

panel_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭──────────── PANEL MANAGEMENT ────────────╮${RESET}"
        echo -e "  ${CYAN}  [1]${RESET} ${WHITE}Panel Installation${RESET}"
        echo -e "  ${BLUE}  [2]${RESET} ${WHITE}Wings Installation${RESET}"
        echo -e "  ${RED}   [3]${RESET} ${WHITE}Uninstall Tools${RESET}"
        echo -e "  ${PURPLE} [4]${RESET} ${WHITE}Blueprint / Themes / Extensions${RESET}"
        echo -e "  ${ORANGE} [5]${RESET} ${WHITE}Cloudflare Tunnel Connect${RESET}"
        echo -e "  ${GREEN}  [6]${RESET} ${WHITE}${BOLD}System Information${RESET}"
        echo -e "  ${CYAN}  [7]${RESET} ${WHITE}Tailscale Setup${RESET}"
        echo -e "  ${BLUE}  [8]${RESET} ${WHITE}Database Setup${RESET}"
        echo -e "  ${RED}   [9]${RESET} ${GRAY}Back to Main Menu${RESET}"
        echo -e "  ${WHITE}${BOLD}╰──────────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            1) run_module "panel.sh" ;;
            2) run_module "wings.sh" ;;
            3) run_module "uninstall.sh" ;;
            4) run_module "blueprint.sh" ;;
            5) run_module "cloudflare.sh" ;;
            6) run_system_info ;;
            7) run_module "tailscale.sh" ;;
            8) run_module "database.sh" ;;
            9) return ;;
            *) echo -e "\n${RED}  ✗ Invalid option. Choose 1-9.${RESET}"; sleep 1 ;;
        esac
    done
}

main_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭────────────── MAIN MENU ──────────────╮${RESET}"
        echo -e "  ${PURPLE}  [A]${RESET} ${WHITE}Panel Management${RESET}"
        echo -e "  ${CYAN}  [B]${RESET} ${WHITE}VPS Maker${RESET}"
        echo -e "  ${GREEN}  [C]${RESET} ${WHITE}Tools & Utilities${RESET}"
        echo -e "  ${ORANGE} [D]${RESET} ${WHITE}System Edit${RESET}"
        echo -e "  ${RED}   [E]${RESET} ${WHITE}Exit Toolkit${RESET}"
        echo -e "  ${WHITE}${BOLD}╰────────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            A|a) loading; panel_menu ;;
            B|b) run_module "vps-maker.sh" ;;
            C|c) run_module "tools.sh" ;;
            D|d) run_module "system-edit.sh" ;;
            E|e)
                echo
                line
                echo -e "  ${PINK}${BOLD}Thank you for using PRITAM Toolkit!${RESET}"
                echo -e "  ${CYAN}Made by Pritam. Goodbye!${RESET}"
                line
                exit 0
                ;;
            *) echo -e "\n${RED}  ✗ Invalid option. Choose A-E.${RESET}"; sleep 1 ;;
        esac
    done
}

# Startup dependency check
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is required to download modules.${RESET}"
    echo "Install using: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

loading
echo -e "${GREEN}${BOLD}  ✓ PRITAM Toolkit loaded successfully!${RESET}"
sleep 1

main_menu
