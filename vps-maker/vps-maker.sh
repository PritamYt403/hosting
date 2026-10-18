#!/usr/bin/env bash

# ==================================================
#       PRITAM HOSTING - VPS MAKER TOOLKIT
#                  VERSION 26.1
# ==================================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;75m'
MAGENTA='\033[38;5;177m'
CYAN='\033[38;5;51m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'
ORANGE='\033[38;5;208m'

BASE="https://raw.githubusercontent.com/sdgamer8263-sketch/VPS/main"

# ==================================================
# UI FUNCTIONS
# ==================================================

line() {
    echo -e "${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

print_status() {
    echo -e "\n  ${2}${BOLD}▶ $1${RESET}\n"
}

loading() {
    local msg="$1"
    local duration="${2:-1}"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end=$((SECONDS + duration))

    while (( SECONDS < end )); do
        for frame in "${frames[@]}"; do
            printf "\r  ${CYAN}%s${RESET} %s" "$frame" "$msg"
            sleep 0.08
        done
    done

    printf "\r  ${GREEN}✔${RESET} %s\n" "$msg"
}

banner() {
    echo -e "${GREEN}${BOLD}"
    cat <<'EOF'
   ██████  ██████  ██ ████████  █████  ███    ███
  ██      ██       ██    ██    ██   ██ ████  ████
  ██      ██   ███ ██    ██    ███████ ██ ████ ██
  ██      ██    ██ ██    ██    ██   ██ ██  ██  ██
   ██████  ██████  ██    ██    ██   ██ ██      ██
EOF
    echo -e "${RESET}"
    echo -e "       ${ORANGE}${BOLD}P R I T A M   H O S T I N G${RESET}"
    echo -e "           ${GRAY}VPS MAKER TOOLKIT V26.1${RESET}"
}

print_menu() {
    clear
    banner
    echo
    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮"
    echo -e "  │${WHITE}${BOLD}        D E V E L O P M E N T   M E N U  (V26.1)      ${CYAN}│"
    echo -e "  ├──────────────────────────────────────────────────────┤"
    echo -e "  │                                                      │"
    echo -e "  │   ${GREEN}[1]${RESET} Environment Tool                               ${CYAN}│"
    echo -e "  │   ${YELLOW}[2]${RESET} Run Virtual Machine Installer (KVM)            ${CYAN}│"
    echo -e "  │   ${BLUE}[3]${RESET} Run Virtual Machine Installer (No KVM)         ${CYAN}│"
    echo -e "  │   ${MAGENTA}[4]${RESET} Proxmox Setup                                  ${CYAN}│"
    echo -e "  │   ${RED}[5]${RESET} Exit                                           ${CYAN}│"
    echo -e "  │                                                      │"
    echo -e "  ╰──────────────────────────────────────────────────────╯${RESET}"
    echo
}

pause_menu() {
    echo
    read -r -p "$(echo -e "  ${CYAN}↩${RESET} Press Enter to return...")" _
}

# Download and run a remote script safely.
run_remote() {
    local script="$1"
    local tmp

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "  ${RED}✖ curl is not installed.${RESET}"
        return 1
    fi

    tmp="$(mktemp)" || {
        echo -e "  ${RED}✖ Could not create temporary file.${RESET}"
        return 1
    }

    echo -e "  ${CYAN}🌐 Source:${RESET} ${WHITE}${script}${RESET}"
    loading "Connecting to GitHub..." 1

    if ! curl -fLsS --connect-timeout 15 --max-time 120 \
        "${BASE}/${script}" -o "$tmp"; then
        echo -e "\n  ${RED}✖ Download failed: ${script}${RESET}"
        echo -e "  ${YELLOW}Check your internet connection and script URL.${RESET}"
        rm -f "$tmp"
        return 1
    fi

    if [[ ! -s "$tmp" ]]; then
        echo -e "  ${RED}✖ Downloaded script is empty.${RESET}"
        rm -f "$tmp"
        return 1
    fi

    echo -e "  ${GREEN}✔ Download complete. Starting script...${RESET}\n"
    bash "$tmp"
    local status=$?

    rm -f "$tmp"

    if (( status == 0 )); then
        echo -e "\n  ${GREEN}✔ Script finished.${RESET}"
    else
        echo -e "\n  ${RED}✖ Script exited with status ${status}.${RESET}"
    fi

    return "$status"
}

# ==================================================
# OPTION 1 - YOUR ENVIRONMENT SETUP
# ==================================================

environment_setup() {
    clear
    print_status "Running Environment Tool Setup..." "$GREEN"
    line

    local home_dir="$HOME"
    local idx_dir="${home_dir}/vm/.idx"
    local config="${idx_dir}/dev.nix"

    echo -e "  ${CYAN}📁 Checking environment directory...${RESET}"
    mkdir -p "$idx_dir" || {
        echo -e "  ${RED}✖ Could not create ${idx_dir}${RESET}"
        return 1
    }

    if [[ -f "$config" ]]; then
        echo -e "  ${YELLOW}⚠ dev.nix already exists; keeping your current file.${RESET}"
    else
        echo -e "  ${CYAN}📝 Creating dev.nix configuration...${RESET}"

        cat > "$config" <<'EOF'
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
EOF

        if [[ $? -ne 0 ]]; then
            echo -e "  ${RED}✖ Failed to write dev.nix.${RESET}"
            return 1
        fi
    fi

    echo
    line
    echo -e "  ${GREEN}${BOLD}✔ Environment setup complete!${RESET}"
    echo
    echo -e "  ${CYAN}╭────────────────────────────────────────╮"
    echo -e "  │ ${WHITE}Status:${RESET}   ${GREEN}Ready${CYAN}                       │"
    echo -e "  │ ${WHITE}Location:${RESET} ${YELLOW}~/vm/.idx/dev.nix${CYAN}       │"
    echo -e "  ╰────────────────────────────────────────╯${RESET}"
    echo
    echo -e "  ${GRAY}Note: Packages apply when your IDX environment"
    echo -e "  reloads or rebuilds its Nix configuration.${RESET}"
}

# ==================================================
# MAIN MENU
# ==================================================

while true; do
    print_menu

    read -r -p "$(echo -e "  ${CYAN}▶${RESET} ${BOLD}Select Option:${RESET} ")" op

    case "$op" in
        1)
            environment_setup
            pause_menu
            ;;

        2)
            clear
            print_status "Starting Virtual Machine Installer (KVM)..." "$YELLOW"
            line
            run_remote "Vm1"
            pause_menu
            ;;

        3)
            clear
            print_status "Starting Virtual Machine Installer (No KVM)..." "$BLUE"
            line

            run_remote "Dd"
            dd_status=$?

            if (( dd_status == 0 )); then
                echo
                run_remote "Vm2"
            else
                echo -e "  ${RED}⚠ Dd script failed; skipping Vm2.${RESET}"
            fi

            pause_menu
            ;;

        4)
            clear
            print_status "Starting Proxmox Setup..." "$MAGENTA"
            line
            run_remote "Proxmox"
            pause_menu
            ;;

        5)
            clear
            echo
            line
            echo -e "  ${ORANGE}${BOLD}       THANK YOU FOR USING PRITAM HOSTING${RESET}"
            echo -e "  ${GREEN}       Have a great day! 👋${RESET}"
            line
            echo
            exit 0
            ;;

        *)
            echo -e "\n  ${RED}${BOLD}✖ Invalid option! Please select 1-5.${RESET}"
            sleep 1
            ;;
    esac
done
