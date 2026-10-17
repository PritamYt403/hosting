
#!/usr/bin/env bash

set -Ee

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${PURPLE}"
echo "===================================="
echo "   PRITAM CLOUDFLARE CONNECT"
echo "===================================="
echo -e "${RESET}"

if ! command -v apt-get >/dev/null 2>&1; then
    echo -e "${RED}This script requires an apt-based Linux system.${RESET}"
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Please install sudo or run as root."
        exit 1
    fi
    SUDO="sudo"
fi

echo "Installing required packages..."
$SUDO apt-get update
$SUDO apt-get install -y curl ca-certificates

echo "Adding Cloudflare signing key..."
$SUDO install -d -m 0755 /usr/share/keyrings

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg |
    $SUDO tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

echo "Adding Cloudflare repository..."
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' |
    $SUDO tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

echo "Installing cloudflared..."
$SUDO apt-get update
$SUDO apt-get install -y cloudflared

echo -e "${GREEN}Cloudflare Tunnel installed successfully!${RESET}"
echo
echo "Starting temporary tunnel for localhost:443 ..."
echo "Press Ctrl+C to stop."
echo

cloudflared tunnel --url https://localhost:443
