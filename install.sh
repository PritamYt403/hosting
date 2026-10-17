
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

# Cloudflare Connect
cloudflare_connect() {
    while true; do
        header
        echo -e "${CYAN}    PRITAM CLOUDFLARE CONNECT${RESET}"
        echo "────────────────────────────────"
        echo "1) Install Cloudflare Tunnel"
        echo "2) Login to Cloudflare"
        echo "3) Start Temporary Tunnel"
        echo "4) Back"
        echo "────────────────────────────────"
        read -rp "Select [1-4]: " cf_choice

        case "$cf_choice" in
            1)
                if command -v cloudflared >/dev/null 2>&1; then
                    echo -e "${GREEN}cloudflared is already installed.${RESET}"
                    pause
                    continue
                fi

                if ! command -v apt-get >/dev/null 2>&1; then
                    echo -e "${RED}This installer requires an apt-based system.${RESET}"
                    pause
                    continue
                fi

                if ! command -v sudo >/dev/null 2>&1; then
                    if [ "$(id -u)" -ne 0 ]; then
                        echo -e "${RED}Run as root or install sudo first.${RESET}"
                        pause
                        continue
                    fi
                    SUDO=""
                else
                    SUDO="sudo"
                fi

                echo "Installing dependencies..."
                if ! $SUDO apt-get update ||
                   ! $SUDO apt-get install -y curl ca-certificates; then
                    echo -e "${RED}Dependency installation failed.${RESET}"
                    pause
                    continue
                fi

                echo "Adding official Cloudflare package repository..."
                if ! curl -fsSL \
                    https://pkg.cloudflare.com/cloudflare-main.gpg |
                    $SUDO tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null; then
                    echo -e "${RED}Could not download Cloudflare key.${RESET}"
                    pause
                    continue
                fi

                echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" |
                    $SUDO tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

                if $SUDO apt-get update &&
                   $SUDO apt-get install -y cloudflared; then
                    echo -e "${GREEN}Cloudflare Tunnel installed!${RESET}"
                else
                    echo -e "${RED}Installation failed. Check the error above.${RESET}"
                fi
                pause
                ;;
            2)
                if ! command -v cloudflared >/dev/null 2>&1; then
                    echo "Install Cloudflare Tunnel first (option 1)."
                    pause
                    continue
                fi
                cloudflared tunnel login
                pause
                ;;
            3)
                if ! command -v cloudflared >/dev/null 2>&1; then
                    echo "Install Cloudflare Tunnel first (option 1)."
                    pause
                    continue
                fi
                echo
                read -rp "Local service port [8080]: " cf_port
                cf_port=${cf_port:-8080}

                if [[ ! "$cf_port" =~ ^[0-9]+$ ]] ||
                   (( cf_port < 1 || cf_port > 65535 )); then
                    echo -e "${RED}Invalid port number.${RESET}"
                    pause
                    continue
                fi

                echo -e "${YELLOW}Starting temporary tunnel to localhost:${cf_port}${RESET}"
                echo "Press Ctrl+C to stop the tunnel."
                cloudflared tunnel --url "http://localhost:${cf_port}"
                pause
                ;;
            4) return ;;
            *)
                echo -e "${RED}Invalid choice!${RESET}"
                sleep 1
                ;;
        esac
    done
}

panel_menu() {
    while true; do
        header
        echo "────────────────────────────────"
        echo -e "${CYAN}       PRITAM PANEL MENU${RESET}"
        echo "────────────────────────────────"
        echo "1) Panel Installation"
        echo "2) Wings Installation"
        echo "3) Uninstall Tools"
        echo "4) Blueprint+Theme+Extensions"
        echo "5) Cloudflare Setup"
        echo "6) System Information"
        echo "7) Tailscale (install + up)"
        echo "8) Database Setup"
        echo "9) Exit"
        echo "────────────────────────────────"
        read -rp "Select an option [1-9]: " choice

        case "$choice" in
            1) demo ;;
            2) demo ;;
            3) demo ;;
            4) demo ;;
            5) cloudflare_connect ;;
            6)
                header
                uname -a
                echo
                df -h
                echo
                if command -v free >/dev/null 2>&1; then
                    free -h
                fi
                pause
                ;;
            7) demo ;;
            8) demo ;;
            9) break ;;
            *)
                echo -e "${RED}Invalid option!${RESET}"
                sleep 1
                ;;
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
            *)
                echo -e "${RED}Invalid option!${RESET}"
                sleep 1
                ;;
        esac
    done
}

loading
echo -e "${GREEN}[✓] PRITAM Loaded Successfully!${RESET}"
sleep 1
main_menu
