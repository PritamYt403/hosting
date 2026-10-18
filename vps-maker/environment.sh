
#!/usr/bin/env bash

# ==============================================
#       PRITAM VPS MAKER - ENVIRONMENT TOOL
#                    VERSION 26.1
# ==============================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

print_header() {
    clear
    printf '\n%b\n' "${GREEN}${BOLD}"
    printf '%s\n' "  ██████  ██████   ██████   █████  ███    ███"
    printf '%s\n' "  ██      ██   ██ ██       ██   ██ ████  ████"
    printf '%s\n' "   █████  ██   ██ ██   ███ ███████ ██ ████ ██"
    printf '%s\n' "       ██ ██   ██ ██    ██ ██   ██ ██  ██  ██"
    printf '%s\n' "  ██████  ██████   ██████  ██   ██ ██      ██"
    printf '%b\n' "${RESET}"
    printf '%b\n' "${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}"
    printf '%b\n' "${CYAN}  │${WHITE}${BOLD}              ENVIRONMENT TOOL V26.1                 ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  ├──────────────────────────────────────────────────────┤${RESET}"
    printf '%b\n' "${CYAN}  │${WHITE}  Configure the development workspace safely         ${CYAN}│${RESET}"
    printf '%b\n\n' "${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}"
}

pause() {
    printf '\n'
    read -r -p "  ↩ Press Enter to return..." _
}

setup_environment() {
    local workspace="$HOME/vm/.idx"
    local config="$workspace/dev.nix"
    local temp

    printf '\n%b\n' "${CYAN}▶ Preparing environment...${RESET}"

    if ! command -v mkdir >/dev/null 2>&1; then
        printf '%b\n' "${RED}✘ mkdir is unavailable.${RESET}"
        return 1
    fi

    if ! mkdir -p "$workspace"; then
        printf '%b\n' "${RED}✘ Could not create: $workspace${RESET}"
        return 1
    fi

    # Keep an existing configuration instead of overwriting it.
    if [ -f "$config" ]; then
        printf '\n%b\n' "${YELLOW}⚠ dev.nix already exists; leaving it unchanged.${RESET}"
        printf '%b\n' "${CYAN}Location: $config${RESET}"
        return 0
    fi

    temp="$(mktemp "$workspace/dev.nix.tmp.XXXXXX")" || {
        printf '%b\n' "${RED}✘ Could not create temporary configuration.${RESET}"
        return 1
    }

    if ! cat > "$temp" <<'EOF'
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
    then
        rm -f "$temp"
        printf '%b\n' "${RED}✘ Failed to write dev.nix.${RESET}"
        return 1
    fi

    if ! mv "$temp" "$config"; then
        rm -f "$temp"
        printf '%b\n' "${RED}✘ Could not save dev.nix.${RESET}"
        return 1
    fi

    printf '\n%b\n' "${GREEN}${BOLD}✔ Environment configuration created!${RESET}"
    printf '%b\n' "${CYAN}  ┌──────────────────────────────────────┐${RESET}"
    printf '%b\n' "${CYAN}  │${WHITE} Status:   ${GREEN}Configuration ready${CYAN}      │${RESET}"
    printf '%b\n' "${CYAN}  │${WHITE} Location: ${YELLOW}~/vm/.idx/dev.nix${CYAN}       │${RESET}"
    printf '%b\n' "${CYAN}  └──────────────────────────────────────┘${RESET}"
    printf '\n%b\n' "${YELLOW}Note: Packages are installed by the supported IDX/Nix environment, not by this script itself.${RESET}"
}

while true; do
    print_header

    printf '%b\n' "${GREEN}  [1]${WHITE} Configure Environment${RESET}"
    printf '%b\n' "${BLUE}  [2]${WHITE} Show Configuration Path${RESET}"
    printf '%b\n' "${RED}  [0]${WHITE} Return / Exit${RESET}"

    printf '\n%b' "  ${CYAN}▶ Select Option: ${RESET}"
    read -r choice || exit 0

    case "$choice" in
        1)
            setup_environment
            pause
            ;;
        2)
            printf '\n%b\n' "${CYAN}Configuration path:${RESET}"
            printf '  %s\n' "$HOME/vm/.idx/dev.nix"
            if [ -f "$HOME/vm/.idx/dev.nix" ]; then
                printf '%b\n' "${GREEN}✔ Configuration file exists.${RESET}"
            else
                printf '%b\n' "${YELLOW}⚠ Configuration has not been created yet.${RESET}"
            fi
            pause
            ;;
        0)
            printf '\n%b\n' "${GREEN}Returning to VPS Maker...${RESET}"
            exit 0
            ;;
        *)
            printf '\n%b\n' "${RED}✘ Invalid option. Choose 1, 2, or 0.${RESET}"
            sleep 1
            ;;
    esac
done
