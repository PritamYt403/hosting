
#!/usr/bin/env bash

# PRITAM Animated Menu
PURPLE='\033[1;35m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

pause() {
    echo
    read -rp "Press Enter to continue..."
}

loading() {
    echo -ne "${PURPLE}Loading"
    for i in 1 2 3 4 5; do
        echo -ne "."
        sleep 0.15
    done
    echo -e "${RESET}"
}

header() {
    clear
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
    echo "             Made By - Pritam"
    echo
}

demo() {
    echo -e "${YELLOW}[!] This feature is not connected yet.${RESET}"
    echo "No system changes were made."
    pause
}

panel_menu() {
    while true; do
        header
        echo "────────── PANEL MENU ──────────"
        echo "1) Install Panel"
        echo "2) Start Panel"
        echo "3) Stop Panel"
        echo "4) Panel Status"
        echo "5) Back"
        echo "────────────────────────────────"
        read -rp "Select: " choice

        case "$choice" in
            1) demo ;;
            2) demo ;;
            3) demo ;;
            4) demo ;;
            5) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

vps_menu() {
    while true; do
        header
        echo "────────── VPS MAKER ───────────"
        echo "1) Create VPS"
        echo "2) List VPS"
        echo "3) Delete VPS"
        echo "4) Back"
        echo "────────────────────────────────"
        read -rp "Select: " choice

        case "$choice" in
            1) demo ;;
            2) demo ;;
            3) demo ;;
            4) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

tools_menu() {
    while true; do
        header
        echo "──────────── TOOLS ─────────────"
        echo "1) System Information"
        echo "2) Disk Usage"
        echo "3) Memory Usage"
        echo "4) Back"
        echo "────────────────────────────────"
        read -rp "Select: " choice

        case "$choice" in
            1)
                header
                uname -a
                command -v hostname >/dev/null && hostname
                pause
                ;;
            2)
                header
                df -h
                pause
                ;;
            3)
                header
                if command -v free >/dev/null; then
                    free -h
                else
                    echo "Memory command is unavailable."
                fi
                pause
                ;;
            4) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

system_menu() {
    while true; do
        header
        echo "────────── SYSTEM EDIT ─────────"
        echo "1) Show Hostname"
        echo "2) Show Current User"
        echo "3) Show Date and Time"
        echo "4) Back"
        echo "────────────────────────────────"
        read -rp "Select: " choice

        case "$choice" in
            1) hostname; pause ;;
            2) whoami; pause ;;
            3) date; pause ;;
            4) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
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
            B|b) loading; vps_menu ;;
            C|c) loading; tools_menu ;;
            D|d) loading; system_menu ;;
            E|e)
                echo -e "${GREEN}Goodbye!${RESET}"
                exit 0
                ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

loading
echo -e "${GREEN}[✓] PRITAM Loaded Successfully!${RESET}"
sleep 1
main_menu
