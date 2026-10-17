
#!/usr/bin/env bash
set -uo pipefail

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

SUDO=()

pause() {
    echo
    read -r -p "Press Enter to continue..." _
}

banner() {
    clear 2>/dev/null || true
    echo -e "${PURPLE}"
    echo "╔═════════════════════════════════════════════╗"
    echo "║        PRITAM CLOUDFLARED MANAGER           ║"
    echo "╚═════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=()
    elif command -v sudo >/dev/null 2>&1; then
        SUDO=(sudo)
    else
        echo -e "${RED}Root access or sudo is required.${RESET}"
        return 1
    fi
}

service_exists() {
    [[ -f /etc/systemd/system/cloudflared.service ||
       -f /lib/systemd/system/cloudflared.service ||
       -f /usr/lib/systemd/system/cloudflared.service ]]
}

install_tunnel() {
    banner
    echo -e "${CYAN}INSTALL / SETUP CLOUDFLARE TUNNEL${RESET}"
    echo

    if ! get_sudo; then
        pause
        return
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        echo -e "${RED}This script requires Ubuntu/Debian.${RESET}"
        pause
        return
    fi

    echo -e "${CYAN}Installing dependencies...${RESET}"
    if ! "${SUDO[@]}" apt-get update ||
       ! "${SUDO[@]}" apt-get install -y curl ca-certificates; then
        echo -e "${RED}Dependency installation failed.${RESET}"
        pause
        return
    fi

    echo -e "${CYAN}Configuring Cloudflare repository...${RESET}"
    "${SUDO[@]}" install -d -m 0755 /usr/share/keyrings || {
        pause
        return
    }

    local key_tmp
    key_tmp=$(mktemp) || {
        echo "Could not create temporary file."
        pause
        return
    }

    if ! curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
        -o "$key_tmp"; then
        rm -f "$key_tmp"
        echo -e "${RED}Could not download Cloudflare signing key.${RESET}"
        pause
        return
    fi

    if ! "${SUDO[@]}" install -m 0644 "$key_tmp" \
        /usr/share/keyrings/cloudflare-main.gpg; then
        rm -f "$key_tmp"
        pause
        return
    fi
    rm -f "$key_tmp"

    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' |
        "${SUDO[@]}" tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

    if ! "${SUDO[@]}" apt-get update ||
       ! "${SUDO[@]}" apt-get install -y cloudflared; then
        echo -e "${RED}Cloudflared installation failed.${RESET}"
        pause
        return
    fi

    echo -e "${GREEN}Cloudflared installed successfully.${RESET}"

    if service_exists; then
        echo
        echo -e "${YELLOW}Existing Cloudflared service detected.${RESET}"
        read -r -p "Replace its configuration? (yes/no): " confirm

        if [[ "$confirm" != "yes" ]]; then
            echo "Existing service kept."
            pause
            return
        fi

        "${SUDO[@]}" cloudflared service uninstall 2>/dev/null || true
        "${SUDO[@]}" systemctl disable --now cloudflared 2>/dev/null || true
    fi

    echo
    echo -e "${CYAN}Paste your Cloudflare Tunnel token.${RESET}"
    echo "Accepted formats:"
    echo "  1. The token only"
    echo "  2. cloudflared tunnel run --token YOUR_TOKEN"
    echo "  3. sudo cloudflared tunnel run --token YOUR_TOKEN"
    echo
    read -r -s -p "> " token
    echo

    # Remove leading and trailing whitespace.
    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"

    # Extract the token from a recognized command.
    if [[ "$token" =~ ^(sudo[[:space:]]+)?cloudflared[[:space:]]+tunnel[[:space:]]+run[[:space:]]+--token[[:space:]]+(.+)$ ]]; then
        token="${BASH_REMATCH[2]}"
    elif [[ "$token" =~ ^(sudo[[:space:]]+)?cloudflared[[:space:]]+service[[:space:]]+install[[:space:]]+(.+)$ ]]; then
        token="${BASH_REMATCH[2]}"
    elif [[ "$token" == sudo\ cloudflared* ||
            "$token" == cloudflared* ]]; then
        echo -e "${RED}Command format not recognized.${RESET}"
        echo "Paste the token only, or the complete supported command."
        unset token
        pause
        return
    fi

    # Remove matching outer quotes.
    if [[ ${#token} -ge 2 ]]; then
        if [[ "$token" == \"*\" && "$token" == *\" ]]; then
            token="${token:1:${#token}-2}"
        elif [[ "$token" == \'*\' ]]; then
            token="${token:1:${#token}-2}"
        fi
    fi

    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"

    if [[ -z "$token" || "$token" == *[[:space:]]* ||
          "$token" == *--token* ]]; then
        echo -e "${RED}Invalid token format.${RESET}"
        echo "Copy the complete tunnel token from your Cloudflare dashboard."
        unset token
        pause
        return
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "${RED}systemd is required for service installation.${RESET}"
        unset token
        pause
        return
    fi

    echo
    echo -e "${CYAN}Installing tunnel service...${RESET}"

    if "${SUDO[@]}" cloudflared service install "$token"; then
        unset token

        if "${SUDO[@]}" systemctl enable --now cloudflared &&
           systemctl is-active --quiet cloudflared; then
            echo
            echo -e "${GREEN}Tunnel installed and running successfully!${RESET}"
        else
            echo -e "${YELLOW}Service installed, but startup needs checking.${RESET}"
            echo "Logs: sudo journalctl -u cloudflared -n 50 --no-pager"
        fi
    else
        unset token
        echo -e "${RED}Tunnel setup failed.${RESET}"
        echo "Check the token and tunnel settings in Cloudflare."
    fi

    pause
}

check_status() {
    banner

    if ! get_sudo; then
        pause
        return
    fi

    if systemctl is-active --quiet cloudflared 2>/dev/null; then
        echo -e "${GREEN}Cloudflared is RUNNING.${RESET}"
    elif service_exists; then
        echo -e "${YELLOW}Service exists but is NOT RUNNING.${RESET}"
    else
        echo -e "${RED}Cloudflared service is not installed.${RESET}"
    fi

    echo
    "${SUDO[@]}" systemctl --no-pager --full status cloudflared 2>/dev/null || true
    pause
}

uninstall_tunnel() {
    banner
    echo -e "${RED}COMPLETE CLOUDFLARED UNINSTALL${RESET}"
    echo "This removes the service, package and repository."
    echo
    read -r -p "Type YES to confirm: " confirm

    [[ "$confirm" == "YES" ]] || {
        echo "Cancelled."
        pause
        return
    }

    if ! get_sudo; then
        pause
        return
    fi

    "${SUDO[@]}" cloudflared service uninstall 2>/dev/null || true
    "${SUDO[@]}" systemctl disable --now cloudflared 2>/dev/null || true

    if command -v apt-get >/dev/null 2>&1; then
        if ! "${SUDO[@]}" apt-get remove -y cloudflared; then
            echo -e "${RED}Package removal failed.${RESET}"
            pause
            return
        fi
    fi

    "${SUDO[@]}" rm -f /etc/apt/sources.list.d/cloudflared.list
    "${SUDO[@]}" rm -f /usr/share/keyrings/cloudflare-main.gpg

    echo -e "${GREEN}Cloudflared removal completed.${RESET}"
    pause
}

while true; do
    banner
    echo "║                                             ║"
    echo "║  1) Install / Setup Tunnel                  ║"
    echo "║  2) Check Service Status                    ║"
    echo "║  3) Uninstall Completely                    ║"
    echo "║  4) Exit                                    ║"
    echo "║                                             ║"
    echo -e "${PURPLE}╚═════════════════════════════════════════════╝${RESET}"
    echo
    read -r -p "Select an option [1-4]: " choice

    case "$choice" in
        1) install_tunnel ;;
        2) check_status ;;
        3) uninstall_tunnel ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
done
