#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════
#                PRITAM BLUEPRINT TOOLKIT
#                    Professional Edition
# ═══════════════════════════════════════════════════════════

set -o pipefail

# ── PRITAM NEON THEME ─────────────────────────────────────
RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
YELLOW='\033[38;5;220m'
BLUE='\033[38;5;39m'
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'
NC='\033[0m'

LINE="${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── UI HELPERS ────────────────────────────────────────────
print_header() {
    echo
    echo -e "$LINE"
    echo -e "  ${CYAN}$1${NC}"
    echo -e "$LINE"
}

print_status() {
    echo -e "  ${YELLOW}⏳ $1...${NC}"
}

print_success() {
    echo -e "  ${GREEN}✔ $1${NC}"
}

print_error() {
    echo -e "  ${RED}✖ $1${NC}"
}

print_warning() {
    echo -e "  ${YELLOW}⚠ $1${NC}"
}

pause_menu() {
    echo
    read -r -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

# ── PROGRESS ANIMATION ────────────────────────────────────
animate_progress() {
    local pid="$1"
    local message="$2"
    local spin='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}[%c]${NC} ${WHITE}%s${NC} " "${spin:0:1}" "$message"
        spin="${spin:1}${spin:0:1}"
        sleep 0.15
    done

    wait "$pid"
    local status=$?

    if [[ "$status" -eq 0 ]]; then
        printf "\r  ${GREEN}✔${NC} ${WHITE}%-48s${NC}\n" "$message"
    else
        printf "\r  ${RED}✖${NC} ${WHITE}%-48s${NC}\n" "$message"
    fi

    return "$status"
}

# ── WELCOME SCREEN ────────────────────────────────────────
welcome_animation() {
    clear
    echo -e "$LINE"
    echo -e "${CYAN}"
    cat <<'EOF'
 ____  ____  ___ _____ _   _   __  __
|  _ \|  _ \|_ _|_   _| \ | | |  \/  |
| |_) | |_) || |  | | |  \| | | |\/| |
|  __/|  _ < | |  | | | |\  | | |  | |
|_|   |_| \_\___| |_| |_| \_| |_|  |_|

             P R I T A M
    EOF
    echo -e "${NC}"
    echo -e "       ${WHITE}PRITAM BLUEPRINT TOOLKIT${NC}"
    echo -e "       ${GRAY}Panel Extension Manager${NC}"
    echo -e "$LINE"
    sleep 1
}

# ── ROOT CHECK ────────────────────────────────────────────
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_error "Please run this script as root."
        return 1
    fi
}

# ── FRESH INSTALL ─────────────────────────────────────────
install_pritam() {
    print_header "FRESH INSTALLATION"

    check_root || return 1

    if [[ ! -d /var/www/pterodactyl ]]; then
        print_error "Pterodactyl Panel directory not found."
        print_warning "Install the Panel first, then run this option."
        return 1
    fi

    cd /var/www/pterodactyl || return 1

    if ! command -v curl >/dev/null 2>&1 ||
       ! command -v unzip >/dev/null 2>&1; then
        print_status "Installing required packages"
        apt-get update &&
            apt-get install -y curl unzip wget ca-certificates ||
            return 1
    fi

    # Install Node.js only when missing or the version is incorrect.
    if ! command -v node >/dev/null 2>&1 ||
       [[ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)" != "22" ]]; then

        print_header "INSTALLING NODE.JS 22"

        print_status "Preparing Node.js repository"

        if ! curl -fsSL https://deb.nodesource.com/setup_22.x |
            bash -; then
            print_error "Node.js repository setup failed."
            return 1
        fi

        print_status "Installing Node.js"
        apt-get install -y nodejs || return 1
    fi

    node --version
    npm --version
    print_success "Node.js is ready"

    # Yarn
    print_header "INSTALLING DEPENDENCIES"

    if ! command -v yarn >/dev/null 2>&1; then
        print_status "Installing Yarn"

        npm install --global yarn || {
            print_error "Yarn installation failed."
            return 1
        }
    fi

    print_success "Yarn is ready"

    # Download Blueprint release
    print_header "DOWNLOADING BLUEPRINT RELEASE"

    local temp_dir
    temp_dir="$(mktemp -d)" || return 1

    local release_json download_url
    release_json="$(curl -fsSL \
        https://api.github.com/repos/BlueprintFramework/framework/releases/latest)" || {
        rm -rf "$temp_dir"
        print_error "Could not fetch the latest Blueprint release."
        return 1
    }

    download_url="$(python3 -c '
import json, sys
data = json.load(sys.stdin)
for asset in data.get("assets", []):
    if asset.get("name") == "release.zip":
        print(asset.get("browser_download_url", ""))
        break
' <<<"$release_json")"

    if [[ -z "$download_url" ]]; then
        rm -rf "$temp_dir"
        print_error "No release.zip was found in the latest release."
        return 1
    fi

    print_status "Downloading release"
    if ! curl -fL --retry 3 "$download_url" -o "$temp_dir/release.zip"; then
        rm -rf "$temp_dir"
        print_error "Release download failed."
        return 1
    fi

    print_status "Validating archive"
    if ! unzip -tq "$temp_dir/release.zip" >/dev/null; then
        rm -rf "$temp_dir"
        print_error "Downloaded ZIP archive is invalid."
        return 1
    fi

    print_status "Extracting release"

    if ! unzip -oq "$temp_dir/release.zip" -d "$temp_dir/release"; then
        rm -rf "$temp_dir"
        print_error "Could not extract the release."
        return 1
    fi

    local blueprint_file
    blueprint_file="$(find "$temp_dir/release" -type f -name blueprint.sh -print -quit)"

    if [[ -z "$blueprint_file" ]]; then
        rm -rf "$temp_dir"
        print_error "blueprint.sh was not found in the release."
        return 1
    fi

    # Do not overwrite existing files without asking.
    if [[ -e /var/www/pterodactyl/blueprint.sh ]]; then
        echo
        print_warning "An existing blueprint.sh file was found."
        read -r -p "Replace it? [y/N]: " replace_choice

        if [[ ! "$replace_choice" =~ ^[Yy]$ ]]; then
            rm -rf "$temp_dir"
            print_warning "Installation cancelled."
            return 1
        fi
    fi

    cp "$blueprint_file" /var/www/pterodactyl/blueprint.sh ||
        { rm -rf "$temp_dir"; return 1; }

    chmod +x /var/www/pterodactyl/blueprint.sh
    rm -rf "$temp_dir"

    print_success "Blueprint files prepared"

    print_header "RUNNING BLUEPRINT INSTALLER"
    cd /var/www/pterodactyl || return 1

    bash ./blueprint.sh
}

# ── REINSTALL ─────────────────────────────────────────────
reinstall_pritam() {
    print_header "RERUN BLUEPRINT INSTALLER"
    check_root || return 1

    cd /var/www/pterodactyl || {
        print_error "Panel directory not found."
        return 1
    }

    command -v blueprint >/dev/null 2>&1 || {
        print_error "Blueprint command not found. Install Blueprint first."
        return 1
    }

    blueprint -rerun-install
}

# ── UPDATE ────────────────────────────────────────────────
update_pritam() {
    print_header "UPDATING BLUEPRINT"
    check_root || return 1

    cd /var/www/pterodactyl || {
        print_error "Panel directory not found."
        return 1
    }

    command -v blueprint >/dev/null 2>&1 || {
        print_error "Blueprint command not found. Install Blueprint first."
        return 1
    }

    blueprint -upgrade
}

# ── MAIN MENU ─────────────────────────────────────────────
show_menu() {
    clear

    echo -e "$LINE"
    echo -e "       ${CYAN}PRITAM BLUEPRINT TOOLKIT${NC}"
    echo -e "       ${GRAY}Professional Management Panel${NC}"
    echo -e "$LINE"
    echo
    echo -e "  ${WHITE}╭──────────────────────────────────────────────╮${NC}"
    echo -e "  ${WHITE}│${NC}             ${PURPLE}MAIN MENU${NC}                     ${WHITE}│${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│${NC}  ${GREEN}1)${NC}  ${CYAN}Fresh Install${NC}                       ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  ${GREEN}2)${NC}  ${CYAN}Reinstall (Rerun Only)${NC}              ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  ${GREEN}3)${NC}  ${CYAN}Update Blueprint${NC}                    ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  ${RED}0)${NC}  Exit                                 ${WHITE}│${NC}"
    echo -e "  ${WHITE}╰──────────────────────────────────────────────╯${NC}"
    echo
    echo -ne "  ${YELLOW}Choose an option [0-3]: ${NC}"
}

# ── MAIN ──────────────────────────────────────────────────
welcome_animation

while true; do
    show_menu
    read -r choice || choice="0"

    case "$choice" in
        1) install_pritam ;;
        2) reinstall_pritam ;;
        3) update_pritam ;;
        0)
            echo
            print_header "THANK YOU FOR USING PRITAM TOOLKIT"
            exit 0
            ;;
        *)
            print_error "Invalid option. Choose 0, 1, 2, or 3."
            ;;
    esac

    pause_menu
done
