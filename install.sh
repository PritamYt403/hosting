
#!/usr/bin/env bash

# ═══════════════════════════════════════════════════
#             PRITAM VPS MANAGEMENT TOOLKIT
#                    Made by Pritam
# ═══════════════════════════════════════════════════

set -o pipefail

BASE="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

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
  ██╔══██╗██╔══██╗██║╚══██╔╝██╔══██╗████╗ ████║
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

# Download and validate a module before executing it.
run_module() {
    local file="$1"
    local tmp
    local url="${BASE}/${file}?v=2"
    local result=0

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}  [ERROR] curl is not installed.${RESET}"
        pause
        return 1
    fi

    tmp="$(mktemp)" || {
        echo -e "${RED}  [ERROR] Cannot create temporary file.${RESET}"
        pause
        return 1
    }

    echo
    echo -e "${CYAN}  [>] Loading module: ${WHITE}${file}${RESET}"
    echo -e "${GRAY}  Downloading from GitHub...${RESET}"

    if ! curl -fsSL --connect-timeout 10 --max-time 60 \
        "$url" -o "$tmp"; then
        echo -e "${RED}  [ERROR] Module download failed.${RESET}"
        echo -e "${YELLOW}  Check the filename and GitHub main branch.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    if [[ ! -s "$tmp" ]] || ! bash -n "$tmp"; then
        echo -e "${RED}  [ERROR] Empty or invalid Bash script.${RESET}"
        rm -f "$tmp"
        pause
        return 1
    fi

    echo -e "${GREEN}  [OK] Script verified. Starting...${RESET}"
    echo

    bash "$tmp" || result=$?
    rm -f "$tmp"

    echo
    if (( result == 0 )); then
        echo -e "${GREEN}  [OK] Module finished successfully.${RESET}"
    else
        echo -e "${YELLOW}  [!] Module exited with code ${result}.${RESET}"
    fi

    pause
    return "$result"
}

# Dedicated System Information launcher.
run_system_info() {
    run_module "system-info.sh"
}

panel_menu() {
    local choice

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
            6) run_system_info ;;
            7) run_module "tailscale.sh" ;;
            8) run_module "database.sh" ;;
            9) return ;;
            *) echo -e "\n${RED}  Invalid option. Choose 1-9.${RESET}"; sleep 1 ;;
        esac
    done
}

main_menu() {
    local choice

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

# Startup checks
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${YELLOW}curl is required to download modules.${RESET}"
    echo "Install it with: sudo apt-get update && sudo apt-get install -y curl"
    exit 1
fi

loading
echo -e "${GREEN}  [✓] PRITAM Toolkit loaded successfully!${RESET}"
sleep 1

main_menu
