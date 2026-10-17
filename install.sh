
#!/usr/bin/env bash

# ═══════════════════════════════════════════
#          PRITAM VPS MANAGEMENT MENU
#               Made by Pritam
# ═══════════════════════════════════════════

set -o pipefail

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

BASE="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

pause() {
    echo
    read -rp "  Press Enter to continue..." _
}

loading() {
    printf "\n${PURPLE}  Loading"
    for _ in 1 2 3 4 5; do
        printf "."
        sleep 0.12
    done
    printf "${RESET}\n\n"
}

header() {
    clear 2>/dev/null || true

    echo -e "${PURPLE}"
    cat <<'EOF'
  ██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗
  ██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║
  ██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║
  ██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║
  ██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${RESET}"

    echo -e "  ${WHITE}VPS MANAGEMENT TOOLKIT${RESET}"
    echo -e "  ${GRAY}Made with care by Pritam${RESET}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

run_module() {
    local file="$1"
    local tmp
    local url="${BASE}/${file}"

    tmp="$(mktemp)" || {
        echo -e "${RED}  [ERROR] Could not create temporary file.${RESET}"
        pause
        return 1
    }

    echo
    echo -e "${CYAN}  [>] Loading module: ${WHITE}${file}${RESET}"
    echo -e "${GRAY}  Downloading latest version from GitHub...${RESET}"

    if ! curl -fsSL --connect-timeout 10 --max-time 60 \
        "$url" -o "$tmp"; then
        echo -e "${RED}  [ERROR] Module download failed.${RESET}"
        echo -e "${YELLOW}  Check the GitHub filename and internet connection.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}  [ERROR] Downloaded module is empty.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    if ! bash -n "$tmp"; then
        echo -e "${RED}  [ERROR] Script syntax check failed.${RESET}"
        echo -e "${YELLOW}  Fix the module on GitHub before running it.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    echo -e "${GREEN}  [OK] Module verified. Starting...${RESET}"
    echo -e "${GRAY}  ──────────────────────────────────────────${RESET}"
    echo

    bash "$tmp"
    local result=$?

    rm -f "$tmp"

    echo
    if (( result == 0 )); then
        echo -e "${GREEN}  [OK] Module finished.${RESET}"
    else
        echo -e "${YELLOW}  [!] Module exited with code ${result}.${RESET}"
    fi

    pause
    return 0
}

panel_menu() {
    while true; do
        header

        echo -e "  ${WHITE}┌────────────── PANEL MENU ──────────────┐${RESET}"
        echo -e "  ${CYAN}  1)${RESET} Panel Installation"
        echo -e "  ${CYAN}  2)${RESET} Wings Installation"
        echo -e "  ${CYAN}  3)${RESET} Uninstall Tools"
        echo -e "  ${CYAN}  4)${RESET} Blueprint / Theme / Extensions"
        echo -e "  ${CYAN}  5)${RESET} Cloudflare Tunnel Connect"
        echo -e "  ${CYAN}  6)${RESET} System Information"
        echo -e "  ${CYAN}  7)${RESET} Tailscale Setup"
        echo -e "  ${CYAN}  8)${RESET} Database Setup"
        echo -e "  ${RED}  9)${RESET} Back to Main Menu"
        echo -e "  ${WHITE}└───────────────────────────────────────┘${RESET}"
        echo

        read -rp "  Select [1-9]: " choice

        case "$choice" in
            1) run_module "panel.sh" ;;
            2) run_module "wings.sh" ;;
            3) run_module "uninstall.sh" ;;
            4) run_module "blueprint.sh" ;;
            5) run_module "cloudflare.sh" ;;
            6) run_module "system-info.sh" ;;
            7) run_module "tailscale.sh" ;;
            8) run_module "database.sh" ;;
            9) return ;;
            *) echo -e "\n${RED}  Invalid option. Choose 1-9.${RESET}"; sleep 1 ;;
        esac
    done
}

main_menu() {
    while true; do
        header

        echo -e "  ${WHITE}┌────────────── MAIN MENU ──────────────┐${RESET}"
        echo -e "  ${CYAN}  A)${RESET} Panel Management"
        echo -e "  ${CYAN}  B)${RESET} VPS Maker"
        echo -e "  ${CYAN}  C)${RESET} Tools"
        echo -e "  ${CYAN}  D)${RESET} System Edit"
        echo -e "  ${RED}  E)${RESET} Exit"
        echo -e "  ${WHITE}└──────────────────────────────────────┘${RESET}"
        echo

        read -rp "  Select [A-E]: " choice

        case "$choice" in
            A|a) loading; panel_menu ;;
            B|b) run_module "vps-maker.sh" ;;
            C|c) run_module "tools.sh" ;;
            D|d) run_module "system-edit.sh" ;;
            E|e)
                echo
                echo -e "${GREEN}  Thank you for using PRITAM Toolkit!${RESET}"
                echo -e "${GRAY}  Goodbye!${RESET}"
                exit 0
                ;;
            *) echo -e "\n${RED}  Invalid option. Choose A-E.${RESET}"; sleep 1 ;;
        esac
    done
}

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${YELLOW}curl is required to download modules.${RESET}"
    echo "Install it with: sudo apt-get install curl"
    exit 1
fi

loading
echo -e "${GREEN}  [✓] PRITAM Toolkit loaded successfully!${RESET}"
sleep 1

main_menu
