#!/bin/bash

# ==========================================
# PRITAM VPS MAKER - DEVELOPMENT MENU
# ==========================================

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# নিজের GitHub repository-র সঠিক script path বসাবে
BASE_URL="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main"

print_menu() {
    clear
    echo -e "${GREEN}${BOLD}"
    echo -e "  ██████  ██████  ██ ████████  █████  ███    ███"
    echo -e "  ██   ██ ██   ██ ██    ██    ██   ██ ████  ████"
    echo -e "  ██████  ██████  ██    ██    ███████ ██ ████ ██"
    echo -e "  ██      ██      ██    ██    ██   ██ ██  ██  ██"
    echo -e "  ██      ██      ██    ██    ██   ██ ██      ██"
    echo -e "${RESET}"

    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}  │${BOLD}${WHITE}             P R I T A M   V P S   M A K E R           ${CYAN}│${RESET}"
    echo -e "${CYAN}  ├──────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  │   ${GREEN}[1]${RESET} Environment Tool                               ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${YELLOW}[2]${RESET} Virtual Machine Installer (KVM)                ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${BLUE}[3]${RESET} Virtual Machine Installer (No KVM)             ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${MAGENTA}[4]${RESET} Proxmox Setup                                  ${CYAN}│${RESET}"
    echo -e "${CYAN}  │   ${RED}[5]${RESET} Exit                                           ${CYAN}│${RESET}"
    echo -e "${CYAN}  │                                                      │${RESET}"
    echo -e "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
    echo
}

print_status() {
    echo -e "\n  ${2}${BOLD}▶ $1${RESET}\n"
}

print_divider() {
    echo -e "  ${DIM}────────────────────────────────────────────────────────${RESET}"
}

run_remote() {
    local script="$1"
    local url="${BASE_URL}/${script}"

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ curl install করা নেই।${RESET}"
        return 1
    fi

    echo -e "  ${CYAN}📡 Downloading: ${script}${RESET}"

    local tmp
    tmp="$(mktemp)" || return 1

    if ! curl -fsSL --connect-timeout 10 "$url" -o "$tmp"; then
        echo -e "${RED}❌ Script download failed: ${script}${RESET}"
        rm -f "$tmp"
        return 1
    fi

    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}❌ Downloaded script empty!${RESET}"
        rm -f "$tmp"
        return 1
    fi

    bash "$tmp"
    local result=$?
    rm -f "$tmp"
    return "$result"
}

pause_menu() {
    echo
    print_divider
    read -rp "  ↩ Press Enter to return..." _
}

while true; do
    print_menu
    read -rp "$(echo -e "  ${CYAN}▶${RESET} ${BOLD}Select Option:${RESET} ")" op

    case "$op" in
        1)
            clear
            print_status "Setting up Environment Tool..." "$GREEN"
            print_divider

            cd "$HOME" || continue
            mkdir -p vm/.idx || {
                echo -e "${RED}❌ Directory create failed.${RESET}"
                pause_menu
                continue
            }

            if [[ ! -f "$HOME/vm/.idx/dev.nix" ]]; then
                cat > "$HOME/vm/.idx/dev.nix" <<'EOF'
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
                echo -e "${GREEN}✅ Environment configuration created!${RESET}"
                echo -e "  Location: ${YELLOW}$HOME/vm/.idx/dev.nix${RESET}"
            else
                echo -e "${YELLOW}⚠ dev.nix already exists; skipped.${RESET}"
            fi

            pause_menu
            ;;

        2)
            clear
            print_status "Starting VM Installer (KVM)..." "$YELLOW"
            print_divider
            run_remote "Vm1"
            pause_menu
            ;;

        3)
            clear
            print_status "Starting VM Installer (No KVM)..." "$BLUE"
            print_divider
            run_remote "Dd"
            run_remote "Vm2"
            pause_menu
            ;;

        4)
            clear
            print_status "Starting Proxmox Setup..." "$MAGENTA"
            print_divider
            run_remote "Proxmox"
            pause_menu
            ;;

        5)
            clear
            echo -e "\n  ${CYAN}╭──────────────────────────────────────────────────────╮${RESET}"
            echo -e "  ${CYAN}│${BOLD}${WHITE}                    PRITAM VPS MAKER                  ${CYAN}│${RESET}"
            echo -e "  ${CYAN}╰──────────────────────────────────────────────────────╯${RESET}\n"
            echo -e "  ${YELLOW}👋 Thanks for using PRITAM VPS MAKER!${RESET}\n"
            exit 0
            ;;

        *)
            echo -e "\n  ${RED}❌ Invalid option! Try again.${RESET}"
            sleep 1
            ;;
    esac
done
