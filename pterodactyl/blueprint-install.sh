
#!/bin/bash

# ==========================================
#          PRITAM BLUEPRINT INSTALLER
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

PANEL_DIR="/var/www/pterodactyl"
RELEASE_URL="https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip"

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_status() {
    echo -e "${YELLOW}⏳ $1...${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${MAGENTA}⚠️  $1${NC}"
}

# Run a command with a spinner and correctly capture its status
run_step() {
    local message="$1"
    shift

    print_status "$message"

    "$@" >/dev/null 2>&1 &
    local pid=$!
    local spin='|/-\'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[%c] %s${NC}" "${spin:i%4:1}" "$message"
        sleep 0.15
        ((i++))
    done

    wait "$pid"
    local status=$?

    printf "\r\033[K"

    if [ "$status" -eq 0 ]; then
        print_success "$message completed"
        return 0
    else
        print_error "$message failed"
        return "$status"
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root."
        return 1
    fi
    return 0
}

check_blueprint() {
    if ! command -v blueprint >/dev/null 2>&1; then
        print_error "Blueprint command not found."
        print_warning "Install Blueprint first using option 1."
        return 1
    fi
    return 0
}

# ==========================================
# FRESH INSTALLATION
# ==========================================

install_pritam() {
    print_header "PRITAM BLUEPRINT INSTALLATION"

    check_root || return 1

    if [ ! -d "$PANEL_DIR" ]; then
        print_error "Pterodactyl directory not found: $PANEL_DIR"
        return 1
    fi

    if ! run_step "Updating package lists" apt-get update; then
        return 1
    fi

    if ! run_step "Installing required packages" \
        apt-get install -y ca-certificates curl gnupg zip unzip git wget; then
        return 1
    fi

    print_header "INSTALLING NODE.JS 22"

    if ! run_step "Setting up Node.js 22 repository" \
        bash -c 'curl -fsSL https://deb.nodesource.com/setup_22.x | bash -'; then
        return 1
    fi

    if ! run_step "Installing Node.js" apt-get install -y nodejs; then
        return 1
    fi

    if ! command -v node >/dev/null 2>&1 ||
       ! command -v npm >/dev/null 2>&1; then
        print_error "Node.js or npm is unavailable."
        return 1
    fi

    echo -e "${CYAN}Node.js:${NC} $(node -v)"
    echo -e "${CYAN}npm:${NC} $(npm -v)"

    if ! run_step "Installing Yarn" npm install -g yarn; then
        return 1
    fi

    print_header "DOWNLOADING BLUEPRINT"

    cd "$PANEL_DIR" || {
        print_error "Cannot access panel directory."
        return 1
    }

    if ! run_step "Downloading Blueprint release" \
        wget -q "$RELEASE_URL" -O "$PANEL_DIR/release.zip"; then
        rm -f "$PANEL_DIR/release.zip"
        return 1
    fi

    if [ ! -s "$PANEL_DIR/release.zip" ]; then
        print_error "Downloaded release is empty."
        rm -f "$PANEL_DIR/release.zip"
        return 1
    fi

    if ! unzip -tq "$PANEL_DIR/release.zip" >/dev/null 2>&1; then
        print_error "Downloaded file is not a valid ZIP."
        rm -f "$PANEL_DIR/release.zip"
        return 1
    fi

    if ! run_step "Extracting Blueprint files" \
        unzip -oq "$PANEL_DIR/release.zip" -d "$PANEL_DIR"; then
        return 1
    fi

    rm -f "$PANEL_DIR/release.zip"

    if [ ! -f "$PANEL_DIR/blueprint.sh" ]; then
        print_error "blueprint.sh not found after extraction."
        return 1
    fi

    print_header "INSTALLING DEPENDENCIES"

    cd "$PANEL_DIR" || return 1

    if ! run_step "Installing Yarn dependencies" yarn install; then
        print_error "Dependency installation failed."
        return 1
    fi

    if ! run_step "Making Blueprint executable" \
        chmod +x "$PANEL_DIR/blueprint.sh"; then
        return 1
    fi

    print_header "RUNNING BLUEPRINT INSTALLER"

    cd "$PANEL_DIR" || return 1
    print_status "Starting Blueprint installer"

    bash "$PANEL_DIR/blueprint.sh"
    local status=$?

    if [ "$status" -eq 0 ]; then
        print_success "Blueprint installer finished."
    else
        print_error "Blueprint installer failed with code $status."
    fi

    return "$status"
}

# ==========================================
# REINSTALL BLUEPRINT
# ==========================================

reinstall_pritam() {
    print_header "REINSTALLING PRITAM BLUEPRINT"

    check_root || return 1
    check_blueprint || return 1

    run_step "Re-running Blueprint installation" \
        blueprint -rerun-install
}

# ==========================================
# UPDATE BLUEPRINT
# ==========================================

update_pritam() {
    print_header "UPDATING PRITAM BLUEPRINT"

    check_root || return 1
    check_blueprint || return 1

    run_step "Updating Blueprint" blueprint -upgrade
}

# ==========================================
# WELCOME SCREEN
# ==========================================

welcome_animation() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗"
    echo "  ██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║"
    echo "  ██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║"
    echo "  ██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║"
    echo "  ██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║"
    echo "  ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝"
    echo -e "${NC}"
    echo -e "${CYAN}              PRITAM TOOLKIT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 1
}

# ==========================================
# MAIN MENU
# ==========================================

show_menu() {
    clear

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}             🔧 PRITAM INSTALLER${NC}"
    echo -e "${CYAN}                 PRITAM HUB${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                 📋 MAIN MENU                  ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  ${GREEN}1)${WHITE} Fresh Install                            ║${NC}"
    echo -e "${WHITE}║  ${GREEN}2)${WHITE} Reinstall (Rerun Only)                   ║${NC}"
    echo -e "${WHITE}║  ${GREEN}3)${WHITE} Update Blueprint                         ║${NC}"
    echo -e "${WHITE}║  ${GREEN}0)${RED} Exit                                     ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ==========================================
# MAIN EXECUTION
# ==========================================

welcome_animation

while true; do
    show_menu
    read -rp "$(echo -e "${YELLOW}📝 Select an option [0-3]: ${NC}")" choice

    case "$choice" in
        1)
            install_pritam
            ;;
        2)
            reinstall_pritam
            ;;
        3)
            update_pritam
            ;;
        0)
            echo
            echo -e "${GREEN}Exiting PRITAM Installer...${NC}"
            echo -e "${CYAN}Thank you for using PRITAM TOOLKIT!${NC}"
            exit 0
            ;;
        *)
            print_error "Invalid option! Choose 0-3."
            ;;
    esac

    echo
    read -rp "Press Enter to return to menu..."
done
