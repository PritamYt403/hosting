
#!/usr/bin/env bash

set -o pipefail

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

is_installed() {
    command -v tailscale >/dev/null 2>&1
}

header() {
    clear 2>/dev/null || true
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}${PURPLE}         TAILSCALE INSTALLER           ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
    echo

    if is_installed; then
        echo -e "Status: ${GREEN}INSTALLED${RESET}"
    else
        echo -e "Status: ${RED}NOT INSTALLED${RESET}"
    fi

    echo
    echo -e "${GRAY}══════════════════════════════════════════${RESET}"
    echo -e "  ${GREEN}[1]${RESET} 📥 Install Tailscale"
    echo -e "  ${RED}[2]${RESET} 🗑️  Uninstall Tailscale"
    echo -e "  ${YELLOW}[3]${RESET} 🚪 Exit"
    echo -e "${GRAY}══════════════════════════════════════════${RESET}"
    echo
}

install_tailscale() {
    if is_installed; then
        echo -e "${YELLOW}Tailscale is already installed.${RESET}"
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run the installer as root (sudo).${RESET}"
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing curl...${RESET}"
        apt-get update && apt-get install -y curl || return 1
    fi

    echo -e "${CYAN}Downloading official Tailscale installer...${RESET}"

    if curl -fsSL https://tailscale.com/install.sh -o /tmp/pritam-tailscale-install.sh; then
        if bash -n /tmp/pritam-tailscale-install.sh; then
            bash /tmp/pritam-tailscale-install.sh
            local result=$?
            rm -f /tmp/pritam-tailscale-install.sh

            if (( result == 0 )); then
                echo -e "${GREEN}Tailscale installation completed.${RESET}"
                echo -e "${CYAN}Connect with: sudo tailscale up${RESET}"
            else
                echo -e "${RED}Installation failed.${RESET}"
            fi
        else
            echo -e "${RED}Installer validation failed.${RESET}"
            rm -f /tmp/pritam-tailscale-install.sh
        fi
    else
        echo -e "${RED}Could not download official installer.${RESET}"
    fi
}

uninstall_tailscale() {
    if ! is_installed; then
        echo -e "${YELLOW}Tailscale is not installed.${RESET}"
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run the installer as root (sudo).${RESET}"
        return
    fi

    echo -e "${YELLOW}This will remove Tailscale from this machine.${RESET}"
    read -rp "Continue? [y/N]: " confirm

    case "$confirm" in
        y|Y|yes|YES)
            if command -v apt-get >/dev/null 2>&1; then
                apt-get remove -y tailscale
            elif command -v dnf >/dev/null 2>&1; then
                dnf remove -y tailscale
            elif command -v yum >/dev/null 2>&1; then
                yum remove -y tailscale
            else
                echo -e "${RED}Unsupported package manager.${RESET}"
                return 1
            fi
            ;;
        *)
            echo "Cancelled."
            ;;
    esac
}

while true; do
    header
    read -rp "Select option [1-3]: " choice

    case "$choice" in
        1)
            install_tailscale
            pause
            ;;
        2)
            uninstall_tailscale
            pause
            ;;
        3)
            echo -e "${GREEN}Goodbye from PRITAM Toolkit!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Choose 1-3.${RESET}"
            sleep 1
            ;;
    esac
done
