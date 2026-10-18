
#!/bin/bash

# ==========================================
# COLOR & STYLE DEFINITIONS
# ==========================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# ==========================================
# UI FUNCTIONS
# ==========================================

print_menu() {
    clear

    # ASCII Banner
    echo -e "${GREEN}${BOLD}"
    echo -e "██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗"
    echo -e "██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║"
    echo -e "██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║"
    echo -e "██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║"
    echo -e "██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║"
    echo -e "╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝"
    echo -e "${RESET}\n"

    # Main Menu Box
    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}  │${BOLD}${WHITE}                 P R I T A M   V P S                  ${CYAN}│${RESET}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  │   ${YELLOW}[1]${RESET} Run Virtual Machine Installer (KVM)            ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${BLUE}[2]${RESET} Run Virtual Machine Installer (No KVM)         ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${RED}[0]${RESET} Exit                                           ${CYAN}│${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
    echo -e ""
}

print_status() {
    local text="$1"
    local color="$2"
    echo -e "\n  ${color}${BOLD}▶ ${text}${RESET}\n"
}

print_divider() {
    echo -e "  ${DIM}────────────────────────────────────────────────────────${RESET}"
}

# ==========================================
# MAIN LOOP
# ==========================================

while true; do
    print_menu

    echo -ne "  ${CYAN}▶${RESET} ${BOLD}Select Option:${RESET} "
    read -r op

    case "$op" in

    # (1) Run VM1 KVM
    1)
        clear
        print_status "🌐 Starting IDX VM (KVM) From GitHub..." "$YELLOW"
        print_divider

        echo -e "  ${CYAN}📡 Fetching script...${RESET}"
        bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/VPS/main/Vm1)

        echo -e ""
        print_divider
        read -rp "  ↩ Press Enter to return..."
        ;;

    # (2) Run VM2 No KVM
    2)
        clear
        print_status "🌐 Starting VM (No KVM) From GitHub..." "$BLUE"
        print_divider

        echo -e "  ${CYAN}📡 Fetching scripts...${RESET}"
        bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/VPS/main/Dd)
        bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/VPS/main/Vm2)

        echo -e ""
        print_divider
        read -rp "  ↩ Press Enter to return..."
        ;;

    # (0) EXIT
    0)
        clear
        echo -e "\n  ${CYAN}╭──────────────────────────────────────────────────────╮${RESET}"
        echo -e "  ${CYAN}│${RESET}${BOLD}${WHITE}                     E X I T I N G                    ${CYAN}│${RESET}"
        echo -e "  ${CYAN}╰──────────────────────────────────────────────────────╯${RESET}\n"
        echo -e "  ${YELLOW}👋 Thank you for using PRITAM VPS!${RESET}\n"
        exit 0
        ;;

    *)
        echo -e "\n  ${RED}❌ Invalid Option! Please try again.${RESET}"
        sleep 1
        ;;
    esac
done
