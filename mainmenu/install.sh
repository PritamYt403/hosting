
#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════
#             PRITAM HOSTING MANAGEMENT
#                  PROFESSIONAL EDITION
#                    Made by Pritam
# ═══════════════════════════════════════════════════════

set -o pipefail

# ── COLORS ─────────────────────────────────────────────
PURPLE='\033[1;35m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
ORANGE='\033[38;5;208m'
PINK='\033[38;5;213m'
RESET='\033[0m'
BOLD='\033[1m'

# ── GITHUB COMMANDS ────────────────────────────────────
PTERODACTYL_URL="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main/install.sh"

HOSTING_BASE="https://raw.githubusercontent.com/PritamYt403/hosting/main/mainmanu"

# ── HELPERS ────────────────────────────────────────────

pause() {
    echo
    read -rp "  Press Enter to continue..." _
}

line() {
    printf "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

loading() {
    printf "\n  ${PURPLE}${BOLD}Initializing Hosting Manager${RESET} "
    for _ in 1 2 3 4 5; do
        printf "${CYAN}◆ ${RESET}"
        sleep 0.10
    done
    echo
    echo
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

# ── DIRECT BASH COMMAND RUNNER ─────────────────────────

run_command() {
    local url="$1"

    echo
    line
    echo -e "${CYAN}${BOLD}  Starting selected service...${RESET}"
    echo -e "${GRAY}  Source: ${url}${RESET}"
    line
    echo

    if ! curl -fsSL --connect-timeout 10 --max-time 60 "$url" |
        bash; then
        echo
        echo -e "${RED}${BOLD}  [ERROR] Command failed.${RESET}"
        echo -e "${YELLOW}  Check the URL, internet connection and script.${RESET}"
        pause
        return 1
    fi

    echo
    echo -e "${GREEN}${BOLD}  [DONE] Command finished.${RESET}"
    pause
}

# ── PANEL MANAGEMENT ───────────────────────────────────

panel_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭────────── PANEL MANAGEMENT ──────────╮${RESET}"
        echo -e "  ${CYAN} [1]${RESET} Pterodactyl Installer"
        echo -e "  ${BLUE} [2]${RESET} Wings Installer"
        echo -e "  ${RED} [3]${RESET} Uninstall Tools"
        echo -e "  ${PURPLE}[4]${RESET} Blueprint / Themes / Extensions"
        echo -e "  ${ORANGE}[5]${RESET} Cloudflare Tunnel"
        echo -e "  ${GREEN} [6]${RESET} System Information"
        echo -e "  ${CYAN} [7]${RESET} Tailscale Setup"
        echo -e "  ${BLUE} [8]${RESET} Database Setup"
        echo -e "  ${RED} [9]${RESET} Back to Main Menu"
        echo -e "  ${WHITE}${BOLD}╰─────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            1) run_command "$PTERODACTYL_URL" ;;
            2) run_command "${HOSTING_BASE}/wings.sh" ;;
            3) run_command "${HOSTING_BASE}/uninstall.sh" ;;
            4) run_command "${HOSTING_BASE}/blueprint.sh" ;;
            5) run_command "${HOSTING_BASE}/cloudflare.sh" ;;
            6) run_command "${HOSTING_BASE}/system-info.sh" ;;
            7) run_command "${HOSTING_BASE}/tailscale.sh" ;;
            8) run_command "${HOSTING_BASE}/database.sh" ;;
            9) return ;;
            *) echo -e "\n${RED}  Invalid option. Choose 1-9.${RESET}"; sleep 1 ;;
        esac
    done
}

# ── MAIN MENU ──────────────────────────────────────────

main_menu() {
    local choice

    while true; do
        header

        echo -e "  ${WHITE}${BOLD}╭────────────── MAIN MENU ──────────────╮${RESET}"
        echo -e "  ${PURPLE} [A]${RESET} ${WHITE}Pterodactyl Management${RESET}"
        echo -e "  ${CYAN} [B]${RESET} ${WHITE}Hosting Manager${RESET}"
        echo -e "  ${GREEN} [C]${RESET} ${WHITE}Tools & Utilities${RESET}"
        echo -e "  ${ORANGE}[D]${RESET} ${WHITE}System Settings${RESET}"
        echo -e "  ${RED} [E]${RESET} ${WHITE}Exit Toolkit${RESET}"
        echo -e "  ${WHITE}${BOLD}╰──────────────────────────────────────╯${RESET}"
        echo

        read -rp "$(echo -e "${PINK}  PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            A|a)
                loading
                panel_menu
                ;;
            B|b)
                run_command "${HOSTING_BASE}/vps-maker.sh"
                ;;
            C|c)
                run_command "${HOSTING_BASE}/tools.sh"
                ;;
            D|d)
                run_command "${HOSTING_BASE}/system-edit.sh"
                ;;
            E|e)
                echo
                line
                echo -e "  ${PINK}${BOLD}Thank you for using PRITAM Hosting Management!${RESET}"
                echo -e "  ${CYAN}Made by Pritam. Goodbye!${RESET}"
                line
                exit 0
                ;;
            *)
                echo -e "\n${RED}  Invalid option. Choose A-E.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ── STARTUP CHECK ──────────────────────────────────────

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is required.${RESET}"
    echo "Install: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

loading
echo -e "${GREEN}${BOLD}  [OK] PRITAM Hosting Management loaded!${RESET}"
sleep 1

main_menu
