
#!/usr/bin/env bash

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
RESET='\033[0m'

BASE="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

loading() {
    echo -ne "${PURPLE}Loading"
    for i in 1 2 3 4 5; do
        echo -n "."
        sleep 0.15
    done
    echo -e "${RESET}"
}

header() {
    clear
    echo -e "${PURPLE}"
    echo '██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗'
    echo '██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║'
    echo '██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║'
    echo '██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║'
    echo '██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║'
    echo '╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝'
    echo -e "${RESET}"
    echo "             Made By - Pritam"
    echo
}

run_module() {
    local file="$1"
    local url="${BASE}/${file}"

    echo -e "${CYAN}Launching ${file}...${RESET}"

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Please install curl first.${RESET}"
        read -rp "Press Enter..."
        return
    fi

    local tmp
    tmp="$(mktemp)" || return

    if curl -fsSL --max-time 30 "$url" -o "$tmp"; then
        if bash -n "$tmp"; then
            bash "$tmp"
        else
            echo -e "${RED}Script syntax check failed.${RESET}"
        fi
    else
        echo -e "${RED}Could not download ${file}.${RESET}"
        echo "Check that the file exists in your GitHub repository."
    fi

    rm -f "$tmp"
    echo
    read -rp "Press Enter to return to menu..."
}

panel_menu() {
    while true; do
        header
        echo "────────── PANEL MENU ──────────"
        echo "1) Panel Installation"
        echo "2) Wings Installation"
        echo "3) Uninstall Tools"
        echo "4) Blueprint + Theme + Extensions"
        echo "5) Cloudflare Connect"
        echo "6) System Information"
        echo "7) Tailscale Setup"
        echo "8) Database Setup"
        echo "9) Back"
        echo "────────────────────────────────"
        read -rp "Select [1-9]: " choice

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
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

main_menu() {
    while true; do
        header
        echo "──────────── MAIN MENU ─────────"
        echo -e "${CYAN}A)${RESET} Panel"
        echo -e "${CYAN}B)${RESET} VPS Maker"
        echo -e "${CYAN}C)${RESET} Tools"
        echo -e "${CYAN}D)${RESET} System Edit"
        echo -e "${RED}E)${RESET} Exit"
        echo "────────────────────────────────"
        read -rp "Select: " choice

        case "$choice" in
            A|a) loading; panel_menu ;;
            B|b) run_module "vps-maker.sh" ;;
            C|c) run_module "tools.sh" ;;
            D|d) run_module "system-edit.sh" ;;
            E|e) echo -e "${GREEN}Goodbye!${RESET}"; exit 0 ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

loading
echo -e "${GREEN}[✓] PRITAM Menu Loaded!${RESET}"
sleep 1
main_menu
