
#!/usr/bin/env bash

# ======================================================
#          PRITAM VPS MAKER - DEVELOPMENT V26.1
#                    Made by Pritam
# ======================================================

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

print_menu() {
    clear
    printf '\n'
    printf '%b\n' "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
    printf '%b\n' "${CYAN}  │${WHITE}${BOLD}        D E V E L O P M E N T   M E N U  (${VERSION})      ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  ├──────────────────────────────────────────────────────┤${RESET}"
    printf '%b\n' "${CYAN}  │                                                      │${RESET}"
    printf '%b\n' "${CYAN}  │   ${GREEN}[1]${WHITE} Environment Tool                               ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │   ${GREEN}[2]${WHITE} Run Virtual Machine Installer (KVM)            ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │   ${GREEN}[3]${WHITE} Run Virtual Machine Installer (No KVM)         ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │   ${GREEN}[4]${WHITE} Proxmox Setup                                  ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │   ${RED}[5]${WHITE} Exit                                           ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │                                                      │${RESET}"
    printf '%b\n\n' "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
}

pause_menu() {
    printf '\n'
    read -r -p "  ↩ Press Enter to return to menu..." _
}

run_script() {
    local script="$1"
    local url="${BASE}/${script}"
    local tmp
    local status

    if ! command -v curl >/dev/null 2>&1; then
        printf '\n%b\n' "${RED}✘ curl is not installed.${RESET}"
        pause_menu
        return 1
    fi

    tmp="$(mktemp)" || {
        printf '\n%b\n' "${RED}✘ Could not create temporary file.${RESET}"
        pause_menu
        return 1
    }

    printf '\n%b\n' "${CYAN}📡 Downloading ${script}...${RESET}"

    if ! curl --fail --silent --show-error --location \
        --connect-timeout 10 --max-time 120 "$url" -o "$tmp"; then
        printf '\n%b\n' "${RED}✘ Download failed: ${script}${RESET}"
        printf '%b\n' "${YELLOW}Check that the file exists in the vps-maker folder.${RESET}"
        rm -f "$tmp"
        pause_menu
        return 1
    fi

    if ! bash -n "$tmp"; then
        printf '\n%b\n' "${RED}✘ Syntax check failed. Script not executed.${RESET}"
        rm -f "$tmp"
        pause_menu
        return 1
    fi

    printf '\n%b\n' "${GREEN}✔ Download and syntax check successful.${RESET}"
    printf '%b\n\n' "${YELLOW}▶ Starting ${script}...${RESET}"

    bash "$tmp"
    status=$?
    rm -f "$tmp"

    if [ "$status" -eq 0 ]; then
        printf '\n%b\n' "${GREEN}✔ Script completed.${RESET}"
    else
        printf '\n%b\n' "${RED}✘ Script exited with code ${status}.${RESET}"
    fi

    pause_menu
}

while true; do
    print_menu
    printf '%b' "  ${PURPLE}▶${RESET} ${BOLD}Select Option:${RESET} "
    read -r choice || exit 0

    case "$choice" in
        1)
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
            printf '\n%b\n' "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
            printf '%b\n' "${CYAN}  │${WHITE}${BOLD}                     E X I T I N G                    ${CYAN}│${RESET}"
            printf '%b\n\n' "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
            printf '%b\n\n' "${YELLOW}  Thank you for using PRITAM VPS MAKER!${RESET}"
            exit 0
            ;;
        *)
            printf '\n%b\n' "${RED}✘ Invalid option! Select 1-5.${RESET}"
            sleep 1
            ;;
    esac
done
