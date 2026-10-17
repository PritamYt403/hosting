
#!/usr/bin/env bash

set -Ee

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

pause() {
    echo
    read -rp "Press Enter to continue..."
}

install_tunnel() {
    clear
    echo "┌────────────────────────────────────┐"
    echo "│      Installing Cloudflared        │"
    echo "└────────────────────────────────────┘"

    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo -e "${RED}Run as root or install sudo first.${RESET}"
        pause
        return
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "This script requires an apt-based Linux system."
        pause
        return
    fi

    if ! $SUDO apt-get update ||
       ! $SUDO apt-get install -y curl ca-certificates; then
        echo -e "${RED}Package setup failed.${RESET}"
        pause
        return
    fi

    $SUDO install -d -m 0755 /usr/share/keyrings

    if ! curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg |
        $SUDO tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null; then
        echo -e "${RED}Could not download Cloudflare signing key.${RESET}"
        pause
        return
    fi

    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' |
        $SUDO tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

    if ! $SUDO apt-get update ||
       ! $SUDO apt-get install -y cloudflared; then
        echo -e "${RED}Cloudflared installation failed.${RESET}"
        pause
        return
    fi

    echo -e "${GREEN}✔ Cloudflared installed successfully${RESET}"

    if command -v systemctl >/dev/null 2>&1 &&
       systemctl is-active --quiet cloudflared; then
        echo
        echo -e "${YELLOW}⚠ Existing Cloudflared service detected${RESET}"
        read -rp "Replace existing service with a token tunnel? (yes/no): " confirm

        if [[ "$confirm" != "yes" ]]; then
            echo "Keeping the existing service."
            pause
            return
        fi

        echo "→ Removing old service..."
        $SUDO cloudflared service uninstall || true
        $SUDO systemctl stop cloudflared 2>/dev/null || true
    fi

    echo
    echo "🔑 Paste Cloudflare Tunnel token"
    echo "(Only the token, not the whole command)"
    read -rsp "> " token
    echo

    if [[ -z "$token" ]]; then
        echo -e "${RED}No token provided.${RESET}"
        pause
        return
    fi

    if [[ "$token" == *[[:space:]]* ]]; then
        # Accept the common command format too.
        token=$(printf '%s' "$token" |
            sed -E 's/^[[:space:]]*sudo[[:space:]]+//; s/^[[:space:]]*cloudflared[[:space:]]+tunnel[[:space:]]+run[[:space:]]+--token[[:space:]]+//')
    fi

    token="${token#\"}"
    token="${token%\"}"
    token="${token#\'}"
    token="${token%\'}"

    if [[ "$token" == *[[:space:]]* || "$token" == *--token* ]]; then
        echo -e "${RED}Token format not recognized. Paste the token value only.${RESET}"
        pause
        return
    fi

    echo
    echo "Connecting Tunnel..."

    # Install as a system service without putting the token in shell history.
    if $SUDO cloudflared service install "$token"; then
        $SUDO systemctl enable --now cloudflared
        echo -e "${GREEN}✔ Cloudflare Tunnel service installed.${RESET}"
        echo "Check its status with: sudo systemctl status cloudflared"
    else
        echo -e "${RED}Tunnel service setup failed.${RESET}"
        echo "Check the token and Cloudflare dashboard."
    fi

    unset token
    pause
}

uninstall_tunnel() {
    echo -e "${YELLOW}This removes the cloudflared service and package.${RESET}"
    read -rp "Continue? (yes/no): " confirm
    [[ "$confirm" == "yes" ]] || return

    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    $SUDO cloudflared service uninstall 2>/dev/null || true
    $SUDO systemctl disable --now cloudflared 2>/dev/null || true
    $SUDO apt-get remove -y cloudflared
    $SUDO rm -f /etc/apt/sources.list.d/cloudflared.list
    $SUDO rm -f /usr/share/keyrings/cloudflare-main.gpg

    echo -e "${GREEN}Cloudflared package removed.${RESET}"
    echo "Review any remaining configuration separately."
    pause
}

while true; do
    clear
    echo -e "${PURPLE}"
    echo "╔═════════════════════════════════════════════╗"
    echo "║        CLOUDFLARED MANAGEMENT MENU          ║"
    echo "╠═════════════════════════════════════════════╣"
    echo "║                                             ║"
    echo "║  1) Install / Setup Tunnel                  ║"
    echo "║                                             ║"
    echo "║  2) Uninstall Completely                    ║"
    echo "║                                             ║"
    echo "║  3) Exit                                    ║"
    echo "╚═════════════════════════════════════════════╝"
    echo -e "${RESET}"

    read -rp "Select an option: " choice

    case "$choice" in
        1) install_tunnel ;;
        2) uninstall_tunnel ;;
        3) break ;;
        *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
    esac
done
