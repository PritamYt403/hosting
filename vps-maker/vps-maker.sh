
#!/usr/bin/env bash

# ==============================================
#       PRITAM VPS MAKER - DEVELOPMENT V26.1
# ==============================================

VERSION="V26.1"
BASE="https://raw.githubusercontent.com/PritamYt403/hosting/main/vps-maker"

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

line="  ├──────────────────────────────────────────────────────┤"

print_menu() {
    clear
    printf '\n'
    printf "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}\n"
    printf "${CYAN}  │${WHITE}${BOLD}        D E V E L O P M E N T   M E N U  (${VERSION})      ${CYAN}│${RESET}\n"
    printf "${CYAN}%s${RESET}\n" "$line"
    printf "${CYAN}  │                                                      │${RESET}\n"
    printf "${CYAN}  │   ${GREEN}[1]${WHITE} Environment Tool                               ${CYAN}│${RESET}\n"
    printf "${CYAN}  │   ${GREEN}[2]${WHITE} Run Virtual Machine Installer (KVM)            ${CYAN}│${RESET}\n"
    printf "${CYAN}  │   ${GREEN}[3]${WHITE} Run Virtual Machine Installer (No KVM)         ${CYAN}│${RESET}\n"
    printf "${CYAN}  │   ${GREEN}[4]${WHITE} Proxmox Setup                                  ${CYAN}│${RESET}\n"
    printf "${CYAN}  │   ${RED}[5]${WHITE} Exit                                           ${CYAN}│${RESET}\n"
    printf "${CYAN}  │                                                      │${RESET}\n"
    printf "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}\n\n"
}

pause_menu() {
    printf '\n'
    read -r -p "  ↩ Press Enter to return to menu..."
}

run_script() {
    local script="$1"
    local url="${BASE}/${script}"
    local tmp
    local status

    if ! command -v curl >/dev/null 2>&1; then
        printf "\n%b\n" "${RED}✘ curl is not installed.${RESET}"
        pause_menu
        return
    fi

    tmp="$(mktemp)" || {
        printf "\n%b\n" "${RED}✘ Could not create temporary file.${RESET}"
        pause_menu
        return
    }

    printf "\n%b\n" "${CYAN}📡 Downloading ${script}...${RESET}"

    if ! curl --fail --silent --show-error --location \
        --connect-timeout 10 --max-time 120 "$url" -o "$tmp"; then
        printf "\n%b\n" "${RED}✘ Download failed: ${script}${RESET}"
        rm -f "$tmp"
        pause_menu
        return
    fi

    if ! bash -n "$tmp"; then
        printf "\n%b\n" "${RED}✘ Script syntax check failed. Not executed.${RESET}"
        rm -f "$tmp"
        pause_menu
        return
    fi

    printf "\n%b\n" "${GREEN}✔ Script downloaded and syntax checked.${RESET}"
    printf "%b\n\n" "${YELLOW}▶ Starting ${script}...${RESET}"

    bash "$tmp"
    status=$?
    rm -f "$tmp"

    if [ "$status" -eq 0 ]; then
        printf "\n%b\n" "${GREEN}✔ Script finished.${RESET}"
    else
        printf "\n%b\n" "${RED}✘ Script exited with code ${status}.${RESET}"
    fi

    pause_menu
}

while true; do
    print_menu
    printf "%b" "  ${PURPLE}▶${RESET} ${BOLD}Select Option:${RESET} "
    read -r choice

    case "$choice" in
        1)
            # Add environment.sh to vps-maker before using this option.
            run_script "environment.sh"
            ;;
        2)
            run_script "vm-kvm.sh"
            ;;
        3)
            run_script "vm-nokvm.sh"
            ;;
        4)
            run_script "proxmox.sh"
            ;;
        5)
            clear
            printf "\n%b\n" "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
            printf "%b\n" "${CYAN}  │${WHITE}${BOLD}                     E X I T I N G                    ${CYAN}│${RESET}"
            printf "%b\n\n" "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
            printf "%b\n\n" "${YELLOW}  👋 Thank you for using PRITAM VPS MAKER!${RESET}"
            exit 0
            ;;
        *)
            printf "\n%b\n" "${RED}  ✘ Invalid option! Please select 1-5.${RESET}"
            sleep 1
            ;;
    esac
done
