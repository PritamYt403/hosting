
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

install_tunnel() {
    banner
    echo -e "${CYAN}INSTALL / SETUP TUNNEL${RESET}"
    echo

    if ! get_sudo; then pause; return; fi

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Ubuntu/Debian with apt is required."
        pause
        return
    fi

    if ! "${SUDO[@]}" apt-get update ||
       ! "${SUDO[@]}" apt-get install -y curl ca-certificates; then
        echo -e "${RED}Dependency installation failed.${RESET}"
        pause
        return
    fi

    "${SUDO[@]}" install -d -m 0755 /usr/share/keyrings || {
        pause
        return
    }

    local key_tmp
    key_tmp=$(mktemp) || { pause; return; }

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

    echo -e "${GREEN}✔ Cloudflared installed successfully.${RESET}"

    if systemctl list-unit-files cloudflared.service --no-legend 2>/dev/null |
        grep -q cloudflared.service; then
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
    echo -e "${CYAN}Paste your Cloudflare Tunnel token or full command.${RESET}"
    echo "Examples:"
    echo "  TOKEN"
    echo "  cloudflared tunnel run --token TOKEN"
    echo "  sudo cloudflared tunnel run --token TOKEN"
    echo
    read -r -p "> " input
    echo

    # Trim surrounding whitespace.
    input="$(printf '%s' "$input" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    token="$input"

    # Extract token from a complete command.
    if [[ "$input" =~ ^(sudo[[:space:]]+)?cloudflared[[:space:]]+tunnel[[:space:]]+run[[:space:]]+--token[=[:space:]]+(.+)$ ]]; then
        token="${BASH_REMATCH[2]}"
    elif [[ "$input" =~ ^(sudo[[:space:]]+)?cloudflared[[:space:]]+service[[:space:]]+install[[:space:]]+(.+)$ ]]; then
        token="${BASH_REMATCH[2]}"
    elif [[ "$input" == *"--token"* ]]; then
        # Also handle commands containing --token later in the text.
        token="${input#*--token}"
        token="${token#=}"
        token="$(printf '%s' "$token" | sed 's/^[[:space:]]*//')"
    elif [[ "$input" == sudo\ cloudflared* ||
            "$input" == cloudflared* ]]; then
        echo -e "${RED}Unsupported command format.${RESET}"
        unset input token
        pause
        return
    fi

    # Strip surrounding quotes and whitespace.
    token="$(printf '%s' "$token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ "$token" == \"*\" ]]; then
        token="${token:1:${#token}-2}"
    elif [[ "$token" == \'*\' ]]; then
        token="${token:1:${#token}-2}"
    fi

    # Token must be a single non-empty value.
    if [[ -z "$token" || "$token" == *[[:space:]]* ||
          "$token" == *"--token"* ]]; then
        echo -e "${RED}✘ Token format not recognized.${RESET}"
        echo "Paste the complete token or supported command."
        unset input token
        pause
        return
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "${RED}systemd is required for service installation.${RESET}"
        unset input token
        pause
        return
    fi

    echo
    echo -e "${CYAN}→ Installing tunnel service...${RESET}"

    if "${SUDO[@]}" cloudflared service install "$token"; then
        unset input token

        if "${SUDO[@]}" systemctl enable --now cloudflared &&
           systemctl is-active --quiet cloudflared; then
            echo -e "${GREEN}✔ Tunnel installed and running!${RESET}"
        else
            echo -e "${YELLOW}Service installed; check its startup status.${RESET}"
            echo "Logs: sudo journalctl -u cloudflared -n 50 --no-pager"
        fi
    else
        unset input token
        echo -e "${RED}✘ Tunnel setup failed.${RESET}"
        echo "Check the token and Cloudflare dashboard configuration."
    fi

    pause
}

check_status() {
    banner
    if ! get_sudo; then pause; return; fi

    "${SUDO[@]}" systemctl --no-pager --full status cloudflared || true
    echo
    echo "Logs: sudo journalctl -u cloudflared -n 50 --no-pager"
    pause
}

uninstall_tunnel() {
    banner
    echo -e "${RED}COMPLETE UNINSTALL${RESET}"
    echo "This removes the service, package and repository."
    read -r -p "Type YES to confirm: " confirm

    [[ "$confirm" == "YES" ]] || {
        echo "Cancelled."
        pause
        return
    }

    if ! get_sudo; then pause; return; fi

    "${SUDO[@]}" cloudflared service uninstall 2>/dev/null || true
    "${SUDO[@]}" systemctl disable --now cloudflared 2>/dev/null || true

    if ! "${SUDO[@]}" apt-get remove -y cloudflared; then
        echo -e "${RED}Package removal failed.${RESET}"
        pause
        return
    fi

    "${SUDO[@]}" rm -f /etc/apt/sources.list.d/cloudflared.list
    "${SUDO[@]}" rm -f /usr/share/keyrings/cloudflare-main.gpg

    echo -e "${GREEN}✔ Cloudflared removed.${RESET}"
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
