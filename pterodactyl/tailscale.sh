
#!/usr/bin/env bash

set -o pipefail

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'
BOLD='\033[1m'

ROOT_SCRIPT_URL="https://raw.githubusercontent.com/JishnuTheGamer/Vps/refs/heads/main/cd/root"

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

is_installed() {
    command -v tailscale >/dev/null 2>&1
}

is_connected() {
    is_installed || return 1
    tailscale status --json 2>/dev/null |
        grep -q '"BackendState"[[:space:]]*:[[:space:]]*"Running"'
}

header() {
    clear 2>/dev/null || true

    echo
    echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║       ${PURPLE}${BOLD}PRITAM TAILSCALE MANAGER${RESET}${CYAN}          ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
    echo

    if ! is_installed; then
        echo -e "Status: ${RED}NOT INSTALLED${RESET}"
    elif is_connected && [[ -n "$(tailscale ip -4 2>/dev/null)" ]]; then
        echo -e "Status: ${GREEN}CONNECTED${RESET}"
        echo -e "IPv4:   ${WHITE}$(tailscale ip -4 2>/dev/null | head -n 1)${RESET}"
    else
        echo -e "Status: ${YELLOW}INSTALLED — NOT CONNECTED${RESET}"
    fi

    echo
    echo -e "${GRAY}══════════════════════════════════════════${RESET}"
    echo -e "  ${GREEN}[1]${RESET} 📥 Install & Connect Tailscale"
    echo -e "  ${RED}[2]${RESET} 🗑️  Uninstall Tailscale"
    echo -e "  ${CYAN}[3]${RESET} 🔌 Connect / Login"
    echo -e "  ${YELLOW}[4]${RESET} 🔎 Check Connection"
    echo -e "  ${ORANGE}[5]${RESET} 🔐 Root Password Manager"
    echo -e "  ${PURPLE}[6]${RESET} 🚪 Exit"
    echo -e "${GRAY}══════════════════════════════════════════${RESET}"
    echo
}

install_tailscale() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run this toolkit as root.${RESET}"
        return 1
    fi

    if ! is_installed; then
        if ! command -v curl >/dev/null 2>&1; then
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update && apt-get install -y curl || return 1
            else
                echo -e "${RED}Please install curl first.${RESET}"
                return 1
            fi
        fi

        echo -e "${CYAN}Downloading official Tailscale installer...${RESET}"

        if ! curl -fsSL --connect-timeout 10 --max-time 60 \
            https://tailscale.com/install.sh \
            -o /tmp/pritam-tailscale-install.sh; then
            echo -e "${RED}Download failed.${RESET}"
            rm -f /tmp/pritam-tailscale-install.sh
            return 1
        fi

        if ! bash -n /tmp/pritam-tailscale-install.sh; then
            echo -e "${RED}Installer validation failed.${RESET}"
            rm -f /tmp/pritam-tailscale-install.sh
            return 1
        fi

        bash /tmp/pritam-tailscale-install.sh
        local result=$?
        rm -f /tmp/pritam-tailscale-install.sh

        if (( result != 0 )) || ! is_installed; then
            echo -e "${RED}Installation failed. Not connected.${RESET}"
            return 1
        fi

        echo -e "${GREEN}Tailscale package installed.${RESET}"
    else
        echo -e "${YELLOW}Tailscale is already installed.${RESET}"
    fi

    connect_tailscale
}

connect_tailscale() {
    if ! is_installed; then
        echo -e "${RED}Install Tailscale first.${RESET}"
        return 1
    fi

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run this option as root.${RESET}"
        return 1
    fi

    echo -e "${CYAN}Starting Tailscale connection...${RESET}"
    echo -e "${YELLOW}Complete authentication in your browser if prompted.${RESET}"

    if ! tailscale up; then
        echo -e "${RED}Connection command failed. Not successful yet.${RESET}"
        return 1
    fi

    verify_connection
}

verify_connection() {
    local attempt=0
    local ip=""

    echo
    echo -e "${CYAN}Verifying Tailscale connection...${RESET}"

    while (( attempt < 15 )); do
        ip="$(tailscale ip -4 2>/dev/null | head -n 1)"

        if is_connected && [[ -n "$ip" ]]; then
            echo
            echo -e "${GREEN}${BOLD}✓ TAILSCALE CONNECTION SUCCESSFUL!${RESET}"
            echo -e "${WHITE}Tailscale IPv4: ${ip}${RESET}"
            return 0
        fi

        printf "${YELLOW}Waiting for connection... (%s/15)${RESET}\n" "$((attempt + 1))"
        sleep 2
        ((attempt += 1))
    done

    echo
    echo -e "${RED}Connection NOT verified. No success message shown.${RESET}"
    echo -e "${YELLOW}Check authentication and try Connect / Login again.${RESET}"
    return 1
}

check_connection() {
    if ! is_installed; then
        echo -e "${RED}Tailscale is not installed.${RESET}"
        return 1
    fi

    if is_connected && [[ -n "$(tailscale ip -4 2>/dev/null)" ]]; then
        echo -e "${GREEN}✓ Connection verified successfully.${RESET}"
        echo -e "${WHITE}IPv4: $(tailscale ip -4 | head -n 1)${RESET}"
    else
        echo -e "${RED}Not connected. SUCCESS cannot be shown.${RESET}"
        tailscale status 2>&1 || true
        return 1
    fi
}

uninstall_tailscale() {
    if ! is_installed; then
        echo -e "${YELLOW}Tailscale is not installed.${RESET}"
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run this option as root.${RESET}"
        return
    fi

    echo -e "${YELLOW}This will remove Tailscale from this VPS.${RESET}"
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

root_password_manager() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run this toolkit as root.${RESET}"
        return 1
    fi

    echo
    echo -e "${ORANGE}${BOLD}ROOT PASSWORD MANAGER${RESET}"
    echo -e "${GRAY}──────────────────────────────────────────${RESET}"
    echo -e "${YELLOW}This option runs an external script as root.${RESET}"
    echo -e "${YELLOW}Review its contents before executing it.${RESET}"
    echo
    echo "1) Run external root script"
    echo "2) Change root password directly"
    echo "3) Back"
    echo

    read -rp "Choose [1-3]: " pass_choice

    case "$pass_choice" in
        1)
            local tmp
            tmp="$(mktemp)" || {
                echo -e "${RED}Could not create temporary file.${RESET}"
                return 1
            }

            if curl -fsSL --connect-timeout 10 --max-time 60 \
                "$ROOT_SCRIPT_URL" -o "$tmp"; then

                if bash -n "$tmp"; then
                    echo -e "${CYAN}Running downloaded script...${RESET}"
                    bash "$tmp"
                else
                    echo -e "${RED}Script validation failed. Not executed.${RESET}"
                    rm -f "$tmp"
                    return 1
                fi
            else
                echo -e "${RED}Could not download root script.${RESET}"
                rm -f "$tmp"
                return 1
            fi

            rm -f "$tmp"
            ;;
        2)
            passwd root
            ;;
        3)
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option.${RESET}"
            return 1
            ;;
    esac
}

while true; do
    header
    read -rp "Select option [1-6]: " choice

    case "$choice" in
        1) install_tailscale; pause ;;
        2) uninstall_tailscale; pause ;;
        3) connect_tailscale; pause ;;
        4) check_connection; pause ;;
        5) root_password_manager; pause ;;
        6)
            echo -e "${GREEN}Goodbye from PRITAM Toolkit!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Choose 1-6.${RESET}"
            sleep 1
            ;;
    esac
done

