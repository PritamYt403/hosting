
#!/usr/bin/env bash

set -uo pipefail

# ==========================================
# PRITAM | CLOUDFLARED MANAGEMENT
# ==========================================

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

pause() {
    echo
    read -r -p "Press Enter to continue..." _
}

banner() {
    clear 2>/dev/null || true
    echo -e "${PURPLE}"
    echo "╔═════════════════════════════════════════════╗"
    echo "║        PRITAM CLOUDFLARED MANAGER           ║"
    echo "╠═════════════════════════════════════════════╣"
    echo -e "${RESET}"
}

get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=()
    elif command -v sudo >/dev/null 2>&1; then
        SUDO=(sudo)
    else
        echo -e "${RED}✘ Root access or sudo is required.${RESET}"
        return 1
    fi
}

service_exists() {
    command -v systemctl >/dev/null 2>&1 &&
        systemctl list-unit-files cloudflared.service \
            --no-legend 2>/dev/null | grep -q 'cloudflared.service'
}

service_status() {
    echo
    echo -e "${CYAN}Cloudflared service status:${RESET}"

    if systemctl is-active --quiet cloudflared 2>/dev/null; then
        echo -e "${GREEN}● Running${RESET}"
    elif service_exists; then
        echo -e "${YELLOW}● Installed, but not running${RESET}"
    else
        echo -e "${YELLOW}● Service not installed${RESET}"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        "${SUDO[@]}" systemctl --no-pager --full status cloudflared 2>/dev/null || true
    fi
}

install_tunnel() {
    banner
    echo -e "${CYAN}┌────────────────────────────────────┐"
    echo "│       INSTALL / SETUP TUNNEL       │"
    echo -e "└────────────────────────────────────┘${RESET}"
    echo

    if ! get_sudo; then
        pause
        return
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        echo -e "${RED}✘ This installer requires Ubuntu/Debian with apt.${RESET}"
        pause
        return
    fi

    if ! "${SUDO[@]}" apt-get update ||
       ! "${SUDO[@]}" apt-get install -y curl ca-certificates; then
        echo -e "${RED}✘ Package preparation failed.${RESET}"
        pause
        return
    fi

    echo
    echo -e "${CYAN}→ Configuring Cloudflare package repository...${RESET}"

    if ! "${SUDO[@]}" install -d -m 0755 /usr/share/keyrings; then
        echo -e "${RED}✘ Could not create keyring directory.${RESET}"
        pause
        return
    fi

    local key_tmp
    key_tmp=$(mktemp) || {
        echo -e "${RED}✘ Could not create temporary file.${RESET}"
        pause
        return
    }

    if ! curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg -o "$key_tmp"; then
        rm -f "$key_tmp"
        echo -e "${RED}✘ Could not download Cloudflare signing key.${RESET}"
        pause
        return
    fi

    if ! "${SUDO[@]}" install -m 0644 "$key_tmp" \
        /usr/share/keyrings/cloudflare-main.gpg; then
        rm -f "$key_tmp"
        echo -e "${RED}✘ Could not install signing key.${RESET}"
        pause
        return
    fi
    rm -f "$key_tmp"

    if ! printf '%s\n' \
        'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' |
        "${SUDO[@]}" tee /etc/apt/sources.list.d/cloudflared.list >/dev/null; then
        echo -e "${RED}✘ Could not configure package repository.${RESET}"
        pause
        return
    fi

    if ! "${SUDO[@]}" apt-get update ||
       ! "${SUDO[@]}" apt-get install -y cloudflared; then
        echo -e "${RED}✘ Cloudflared installation failed.${RESET}"
        pause
        return
    fi

    echo -e "${GREEN}✔ Cloudflared installed successfully.${RESET}"

    if service_exists; then
        echo
        echo -e "${YELLOW}⚠ An existing Cloudflared service was detected.${RESET}"
        read -r -p "Replace it with the new tunnel token? (yes/no): " confirm

        if [[ "$confirm" != "yes" ]]; then
            echo "Existing service has been kept."
            pause
            return
        fi

        echo -e "${CYAN}→ Removing old service...${RESET}"
        "${SUDO[@]}" cloudflared service uninstall 2>/dev/null || true
        "${SUDO[@]}" systemctl stop cloudflared 2>/dev/null || true
        "${SUDO[@]}" systemctl disable cloudflared 2>/dev/null || true
    fi

    echo
    echo -e "${CYAN}🔑 Enter your Cloudflare Tunnel token${RESET}"
    echo "You can paste the token OR the full command:"
    echo "cloudflared tunnel run --token YOUR_TOKEN"
    echo
    read -r -s -p "> " token
    echo

    # Trim leading/trailing whitespace.
    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"

    # Accept: sudo cloudflared tunnel run --token TOKEN
    # Accept: cloudflared tunnel run --token TOKEN
    if [[ "$token" =~ ^(sudo[[:space:]]+)?cloudflared[[:space:]]+tunnel[[:space:]]+run[[:space:]]+--token[[:space:]]+(.+)$ ]]; then
        token="${BASH_REMATCH[2]}"
    fi

    # Remove matching outer quotes, if present.
    if [[ ${#token} -ge 2 ]]; then
        if [[ "$token" == \"*\" || "$token" == \'*\' ]]; then
            token="${token:1:${#token}-2}"
        fi
    fi

    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"

    if [[ -z "$token" || "$token" == *[[:space:]]* || "$token" == *--token* ]]; then
        echo -e "${RED}✘ Token format not recognized.${RESET}"
        echo "Paste the token itself or the complete supported command."
        unset token
        pause
        return
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "${RED}✘ systemd is required to install the service.${RESET}"
        unset token
        pause
        return
    fi

    echo
    echo -e "${CYAN}→ Installing and starting tunnel service...${RESET}"

    if "${SUDO[@]}" cloudflared service install "$token"; then
        unset token

        if "${SUDO[@]}" systemctl enable --now cloudflared &&
           systemctl is-active --quiet cloudflared; then
            echo
            echo -e "${GREEN}✔ Cloudflare Tunnel is installed and running!${RESET}"
            echo "Check status: sudo systemctl status cloudflared"
            echo "View logs:    sudo journalctl -u cloudflared -f"
        else
            echo -e "${YELLOW}⚠ Service was installed, but is not confirmed running.${RESET}"
            echo "Check logs: sudo journalctl -u cloudflared -n 50 --no-pager"
        fi
    else
        unset token
        echo -e "${RED}✘ Tunnel service setup failed.${RESET}"
        echo "Check your token and the tunnel configuration in Cloudflare."
    fi

    pause
}

uninstall_tunnel() {
    banner
    echo -e "${RED}┌────────────────────────────────────┐"
    echo "│       COMPLETE UNINSTALL           │"
    echo -e "└────────────────────────────────────┘${RESET}"
    echo
    echo "This removes the cloudflared service, package,"
    echo "repository entry and signing key."
    echo
    read -r -p "Type YES to confirm removal: " confirm

    [[ "$confirm" == "YES" ]] || {
        echo "Uninstall cancelled."
        pause
        return
    }

    if ! get_sudo; then
        pause
        return
    fi

    if command -v systemctl >/dev/null 2>&1; then
        "${SUDO[@]}" cloudflared service uninstall 2>/dev/null || true
        "${SUDO[@]}" systemctl disable --now cloudflared 2>/dev/null || true
    fi

    if command -v apt-get >/dev/null 2>&1; then
        "${SUDO[@]}" apt-get remove -y cloudflared || {
            echo -e "${RED}Package removal failed.${RESET}"
            pause
            return
        }
    else
        echo -e "${YELLOW}apt-get unavailable; package removal skipped.${RESET}"
    fi

    "${SUDO[@]}" rm -f /etc/apt/sources.list.d/cloudflared.list
    "${SUDO[@]}" rm -f /usr/share/keyrings/cloudflare-main.gpg

    echo
    echo -e "${GREEN}✔ Cloudflared package and service removed.${RESET}"
    echo "Review any remaining tunnel configuration separately."
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
        2)
            if ! get_sudo; then
                pause
            else
                service_status
                pause
            fi
            ;;
        3) uninstall_tunnel ;;
        4) echo -e "${GREEN}Goodbye!${RESET}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Choose 1-4.${RESET}"; sleep 1 ;;
    esac
done
