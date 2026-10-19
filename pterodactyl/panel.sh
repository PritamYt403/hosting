
install_traditional(){
    need_root || return 1

    echo
    line
    echo -e "${CYAN} PANEL + WINGS INSTALLATION ${RESET}"
    line

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}[!] curl is required.${RESET}"
        pause_menu
        return 1
    fi

    echo -e "${YELLOW}Official third-party installer will start.${RESET}"
    echo -e "${YELLOW}Choose Panel or Wings in its menu.${RESET}"
    read -r -p "Continue? Type YES: " confirm

    if [[ "$confirm" != "YES" ]]; then
        pause_menu
        return 0
    fi

    bash <(curl -fsSL https://pterodactyl-installer.se) || {
        echo -e "${RED}[!] Installer failed.${RESET}"
        pause_menu
        return 1
    }

    pause_menu
}
