
#!/usr/bin/env bash

# ==========================================================
#       PRITAM HOSTING MANAGER
#       PTERODACTYL CONTROL CENTER
#       Customized by Pritam
# ==========================================================

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

BASE_URL="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl"

line() {
    echo -e "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

pause_menu() {
    echo
    read -rp "Press Enter to return..." _ || true
}

run_script() {
    local file="$1"
    local tmp
    local status=0

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}[!] curl is not installed.${RESET}"
        pause_menu
        return 1
    fi

    # Collect required Panel administrator details
    if [[ "$file" == "pterodactary.sh" ]]; then
        echo
        line
        echo -e "${CYAN}       PTERODACTYL PANEL INSTALLATION${RESET}"
        line
        echo

        read -r -p "SSL certificate email: " email
        read -r -p "Admin email: " user_email
        read -r -p "Admin username: " user_username
        read -r -p "Admin first name: " user_firstname
        read -r -p "Admin last name: " user_lastname
        read -r -s -p "Admin password: " user_password
        echo

        if [[ -z "$email" || -z "$user_email" ||
              -z "$user_username" || -z "$user_firstname" ||
              -z "$user_lastname" || -z "$user_password" ]]; then
            echo -e "${RED}[!] All six fields are required.${RESET}"
            unset email user_email user_username
            unset user_firstname user_lastname user_password
            pause_menu
            return 1
        fi

        # Pass values to the installer process
        export email user_email user_username
        export user_firstname user_lastname user_password
    fi

    tmp="$(mktemp)" || {
        echo -e "${RED}[!] Could not create temporary file.${RESET}"
        unset email user_email user_username
        unset user_firstname user_lastname user_password
        pause_menu
        return 1
    }

    echo
    echo -e "${CYAN}[*] Downloading ${file}...${RESET}"

    if curl -fsSL --connect-timeout 15 --retry 2 \
        "${BASE_URL}/${file}" -o "$tmp"; then

        if [[ ! -s "$tmp" ]]; then
            echo -e "${RED}[!] Downloaded file is empty.${RESET}"
            status=1
        else
            echo -e "${GREEN}[*] Running ${file}...${RESET}"
            bash "$tmp" || status=$?
        fi
    else
        echo -e "${RED}[!] Download failed: ${file}${RESET}"
        echo -e "${YELLOW}Check the GitHub path and internet connection.${RESET}"
        status=1
    fi

    rm -f "$tmp"

    # Remove credentials from this shell
    unset email user_email user_username
    unset user_firstname user_lastname user_password

    echo
    if [[ "$status" -eq 0 ]]; then
        echo -e "${GREEN}[✓] Script completed successfully.${RESET}"
    else
        echo -e "${RED}[!] Script exited with code ${status}.${RESET}"
    fi

    pause_menu
    return 0
}

while true; do
    clear

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}║        ⚡ PRITAM PTERODACTYL CONTROL CENTER                 ║${RESET}"
    echo -e "${CYAN}║        Professional Server Management System                 ║${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

    echo
    line
    echo -e "${YELLOW}  CONTROL MODULES${RESET}"
    line
    echo
    echo -e "  ${GREEN}[1]${WHITE} Panel Installation${RESET}"
    echo -e "      Fresh Pterodactyl Panel Installation"
    echo
    echo -e "  ${RED}[2]${WHITE} Panel Removal${RESET}"
    echo -e "      Remove Panel Data and Configuration"
    echo
    echo -e "  ${RED}[0]${WHITE} Exit System${RESET}"
    echo
    line

    read -r -p "$(echo -e "${YELLOW}  Select an option [0-2]: ${RESET}")" choice || exit 0

    case "$choice" in
        1)
            run_script "pterodactary.sh"
            ;;
        2)
            echo
            echo -e "${RED}WARNING: Panel removal may delete panel data and configuration!${RESET}"
            read -r -p "Type YES to confirm removal: " confirm

            if [[ "$confirm" == "YES" ]]; then
                run_script "uninstall.sh"
            else
                echo -e "${YELLOW}Removal cancelled.${RESET}"
                sleep 1
            fi
            ;;
        0)
            echo -e "${GREEN}Thanks for using Pritam Hosting Manager!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option! Choose 0-2.${RESET}"
            sleep 1
            ;;
    esac
done
