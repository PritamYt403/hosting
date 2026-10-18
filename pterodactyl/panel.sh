
#!/usr/bin/env bash

# ============================================================
#              PRITAM PTERODACTYL CONTROL CENTER
#                         Version 2.2
# ============================================================

set -o pipefail
umask 077

# ---------- PROFESSIONAL COLOR THEME ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
GOLD='\033[38;5;220m'
BOLD='\033[1m'
NC='\033[0m'

PANEL_DIR="/var/www/pterodactyl"
GITHUB_REPO="pterodactyl/panel"

INSTALL_URL="https://raw.githubusercontent.com/PritamYt403/pterodactyl/main/pterodactary.sh"
SSL_URL="https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/ssl.sh"
PHPMYADMIN_URL="https://raw.githubusercontent.com/nobita329/Nobita-Cloud/refs/heads/main/panel/pterodactyl/phpMyAdmin.sh"

# ---------- UI HELPERS ----------
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}       ${BOLD}${WHITE}PRITAM PTERODACTYL CONTROL CENTER${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GRAY}MODULE:${NC} ${GOLD}$1${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo
}

status_msg() {
    case "$1" in
        OK)   echo -e "  ${GREEN}[✔]${NC} $2" ;;
        ERR)  echo -e "  ${RED}[✘]${NC} $2" ;;
        INFO) echo -e "  ${CYAN}[➜]${NC} $2" ;;
        WAIT) echo -e "  ${YELLOW}[...]${NC} $2" ;;
        WARN) echo -e "  ${GOLD}[!]${NC} $2" ;;
    esac
}

pause() {
    echo
    read -r -p "  Press Enter to return to the menu..."
}

panel_exists() {
    [[ -f "$PANEL_DIR/artisan" && -f "$PANEL_DIR/.env" ]]
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        status_msg ERR "Run this tool as root."
        return 1
    fi
}

# Download to a temporary file first, then execute only if successful.
run_remote_script() {
    local url="$1"
    local name="$2"
    local tmp

    tmp="$(mktemp)" || {
        status_msg ERR "Could not create temporary file."
        return 1
    }

    status_msg INFO "Downloading ${name}..."

    if ! curl --fail --location --silent --show-error \
        --connect-timeout 15 --max-time 300 "$url" -o "$tmp"; then
        status_msg ERR "Download failed. Nothing was executed."
        rm -f "$tmp"
        return 1
    fi

    if [[ ! -s "$tmp" ]] || ! bash -n "$tmp"; then
        status_msg ERR "Downloaded script is empty or has a syntax error."
        rm -f "$tmp"
        return 1
    fi

    status_msg INFO "Launching ${name}..."
    bash "$tmp"
    local rc=$?
    rm -f "$tmp"

    if [[ "$rc" -eq 0 ]]; then
        status_msg OK "${name} finished."
    else
        status_msg ERR "${name} exited with status ${rc}."
    fi
    return "$rc"
}

# ==================== 1. INSTALL ====================
install_ptero() {
    show_header "PANEL INSTALLATION"

    if panel_exists; then
        status_msg WARN "A Panel installation already exists."
        status_msg INFO "Use Update for an existing installation."
        pause
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        status_msg ERR "curl is not installed."
        pause
        return
    fi

    run_remote_script "$INSTALL_URL" "Pterodactyl Panel Installer"
    pause
}

# ==================== 2. USER MANAGEMENT ====================
create_user() {
    show_header "USER MANAGEMENT"

    if ! panel_exists; then
        status_msg ERR "Panel installation or .env file not found."
        pause
        return
    fi

    echo -e "  ${GREEN}1)${NC} Create Custom User"
    echo -e "  ${GREEN}2)${NC} Create Random Admin User"
    echo -e "  ${GRAY}0) Back${NC}"
    echo

    read -r -p "  Select option: " choice

    case "$choice" in
        1)
            status_msg INFO "Opening the official user creation command..."
            (
                cd "$PANEL_DIR" || exit 1
                php artisan p:user:make
            )
            ;;
        2)
            if ! command -v openssl >/dev/null 2>&1; then
                status_msg ERR "openssl is required."
                pause
                return
            fi

            local username password email first last
            username="admin$(openssl rand -hex 4)"
            password="$(openssl rand -hex 16)"
            email="admin-$(openssl rand -hex 4)@example.com"
            first="Pritam"
            last="Admin"

            status_msg WAIT "Creating administrator account..."

            if (
                cd "$PANEL_DIR" &&
                php artisan p:user:make -n \
                    --email="$email" \
                    --username="$username" \
                    --password="$password" \
                    --admin=1 \
                    --name-first="$first" \
                    --name-last="$last"
            ); then
                echo
                status_msg OK "Admin account created."
                echo -e "  ${CYAN}Username:${NC} $username"
                echo -e "  ${CYAN}Email:${NC}    $email"
                echo -e "  ${CYAN}Password:${NC} $password"
                status_msg WARN "Save this password securely. Do not share it."
                status_msg INFO "Replace the example email with a real email if needed."
            else
                status_msg ERR "User creation failed. Check the error above."
            fi
            ;;
        0) return ;;
        *) status_msg ERR "Invalid option." ;;
    esac

    pause
}

# ==================== 3. UPDATE ====================
update_panel() {
    show_header "PANEL UPDATE"

    if ! panel_exists; then
        status_msg ERR "Panel not found. Install it first."
        pause
        return
    fi

    for cmd in curl tar composer php; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            status_msg ERR "Required command missing: $cmd"
            pause
            return
        fi
    done

    local workdir archive staging backup version choice
    workdir="$(mktemp -d)" || {
        status_msg ERR "Could not create temporary directory."
        pause
        return
    }

    archive="$workdir/panel.tar.gz"
    staging="$workdir/staging"
    backup="${PANEL_DIR}.backup.$(date +%Y%m%d-%H%M%S)"

    status_msg INFO "Fetching official Panel releases..."

    local json
    if ! json="$(curl -fsSL --connect-timeout 15 --max-time 60 \
        "https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=20")"; then
        status_msg ERR "Could not fetch releases."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        status_msg ERR "python3 is required to read release information."
        rm -rf -- "$workdir"
        pause
        return
    fi

    mapfile -t tags < <(
        printf '%s' "$json" | python3 -c '
import json, sys
try:
    releases = json.load(sys.stdin)
    for release in releases:
        tag = release.get("tag_name", "")
        if tag and not release.get("prerelease", False) and not release.get("draft", False):
            print(tag)
except Exception:
    pass
' | head -20
    )

    if [[ "${#tags[@]}" -eq 0 ]]; then
        status_msg ERR "No stable releases found."
        rm -rf -- "$workdir"
        pause
        return
    fi

    echo
    echo -e "  ${BOLD}${WHITE}Available stable versions${NC}"
    local i
    for i in "${!tags[@]}"; do
        printf "  %b[%d]%b %s\n" "$GREEN" "$((i + 1))" "$NC" "${tags[$i]}"
    done
    echo
    read -r -p "  Select version [1 = latest] (0 = cancel): " choice
    choice="${choice:-1}"

    if [[ "$choice" == "0" ]]; then
        status_msg INFO "Update cancelled."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if [[ ! "$choice" =~ ^[0-9]+$ ]] ||
       (( choice < 1 || choice > ${#tags[@]} )); then
        status_msg ERR "Invalid version selection."
        rm -rf -- "$workdir"
        pause
        return
    fi

    version="${tags[$((choice - 1))]}"

    echo
    status_msg INFO "Selected version: $version"
    status_msg WARN "A backup of the current panel files will be created."
    status_msg WARN "Ensure you also have a recent database backup."
    read -r -p "  Type YES to continue: " confirm

    if [[ "$confirm" != "YES" ]]; then
        status_msg INFO "Update cancelled."
        rm -rf -- "$workdir"
        pause
        return
    fi

    local download_url="https://github.com/${GITHUB_REPO}/releases/download/${version}/panel.tar.gz"

    status_msg WAIT "Downloading release..."

    if ! curl -fL --connect-timeout 15 --max-time 600 \
        "$download_url" -o "$archive"; then
        status_msg ERR "Download failed. Existing panel was not changed."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if ! tar -tzf "$archive" >/dev/null 2>&1; then
        status_msg ERR "Downloaded archive is invalid. Existing panel was not changed."
        rm -rf -- "$workdir"
        pause
        return
    fi

    mkdir -p "$staging"

    if ! tar -xzf "$archive" -C "$staging"; then
        status_msg ERR "Could not extract release."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if [[ ! -f "$staging/artisan" ]]; then
        status_msg ERR "Release archive does not contain the expected Panel files."
        rm -rf -- "$workdir"
        pause
        return
    fi

    # Preserve configuration and user-uploaded storage.
    if ! cp -a "$PANEL_DIR/.env" "$staging/.env"; then
        status_msg ERR "Could not preserve the existing .env file."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if [[ -d "$PANEL_DIR/storage" ]]; then
        if ! cp -a "$PANEL_DIR/storage/." "$staging/storage/"; then
            status_msg ERR "Could not preserve storage files."
            rm -rf -- "$workdir"
            pause
            return
        fi
    fi

    status_msg WAIT "Creating panel file backup..."

    if ! cp -a "$PANEL_DIR" "$backup"; then
        status_msg ERR "Backup failed. Existing panel was not changed."
        rm -rf -- "$workdir"
        pause
        return
    fi

    # Move the old directory aside; do not delete it.
    local olddir="${PANEL_DIR}.old.$$"
    if ! mv "$PANEL_DIR" "$olddir"; then
        status_msg ERR "Could not move existing panel."
        rm -rf -- "$workdir"
        pause
        return
    fi

    if ! mv "$staging" "$PANEL_DIR"; then
        mv "$olddir" "$PANEL_DIR"
        status_msg ERR "Could not install staged release; restored previous files."
        rm -rf -- "$workdir"
        pause
        return
    fi

    status_msg WAIT "Installing dependencies..."

    if ! (
        cd "$PANEL_DIR" &&
        COMPOSER_ALLOW_SUPERUSER=1 composer install \
            --no-dev --optimize-autoloader --no-interaction
    ); then
        status_msg ERR "Composer failed. Restoring previous panel files."
        mv "$PANEL_DIR" "${PANEL_DIR}.failed.$$"
        mv "$olddir" "$PANEL_DIR"
        status_msg WARN "Check database state before trying again."
        status_msg INFO "Backup copy: $backup"
        rm -rf -- "$workdir"
        pause
        return
    fi

    status_msg WAIT "Running migrations..."

    if ! (
        cd "$PANEL_DIR" &&
        php artisan view:clear &&
        php artisan config:clear &&
        php artisan migrate --seed --force &&
        php artisan queue:restart
    ); then
        status_msg ERR "Migration/update failed."
        status_msg WARN "Database migrations may have changed the database."
        status_msg WARN "Do not delete the backup; inspect logs and database before recovery."
        status_msg INFO "File backup: $backup"
        rm -rf -- "$workdir"
        pause
        return
    fi

    chmod -R 755 "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache" 2>/dev/null || true
    chown -R www-data:www-data "$PANEL_DIR"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart pteroq.service 2>/dev/null || true
    fi

    rm -rf -- "$olddir" "$workdir"

    status_msg OK "Panel update completed: $version"
    status_msg INFO "Backup retained at: $backup"
    pause
}

# ==================== 4. DOMAIN & SSL ====================
domain_ssl() {
    show_header "DOMAIN & SSL"

    status_msg WARN "This option runs your configured external SSL script."
    status_msg INFO "Make sure the domain points to this server."

    run_remote_script "$SSL_URL" "Domain and SSL Tool"
    pause
}

# ==================== 5. UNINSTALL ====================
uninstall_logic() {
    status_msg WAIT "Stopping Panel queue service..."
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload

    status_msg WAIT "Removing Panel schedule cron entry..."
    local current_cron
    current_cron="$(crontab -l 2>/dev/null || true)"
    if [[ -n "$current_cron" ]]; then
        printf '%s\n' "$current_cron" |
            grep -vE 'pterodactyl/artisan schedule:run' |
            crontab - 2>/dev/null || true
    fi

    status_msg WARN "Removing Panel files..."
    rm -rf -- "$PANEL_DIR"

    status_msg WARN "Dropping the default Panel database and database user..."
    status_msg WARN "This permanently deletes database 'panel' if it exists."

    if command -v mysql >/dev/null 2>&1; then
        mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || \
            status_msg WARN "Could not drop database automatically; check database credentials."
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1'; FLUSH PRIVILEGES;" \
            2>/dev/null || true
    elif command -v mariadb >/dev/null 2>&1; then
        mariadb -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
        mariadb -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1'; FLUSH PRIVILEGES;" \
            2>/dev/null || true
    fi

    status_msg INFO "Removing the named Pterodactyl Nginx configuration..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    nginx -t >/dev/null 2>&1 && systemctl reload nginx 2>/dev/null || true
}

uninstall_ptero() {
    show_header "PANEL UNINSTALLATION"

    echo -e "  ${RED}${BOLD}WARNING: THIS ACTION IS DESTRUCTIVE${NC}"
    echo -e "  It deletes ${WHITE}${PANEL_DIR}${NC}, the default ${WHITE}panel${NC} database,"
    echo -e "  and the default Pterodactyl database user."
    echo -e "  ${YELLOW}Wings and other databases are not intentionally removed.${NC}"
    echo
    read -r -p "  Type DELETE to confirm: " confirm

    if [[ "$confirm" != "DELETE" ]]; then
        status_msg INFO "Uninstallation cancelled."
        pause
        return
    fi

    uninstall_logic
    echo
    status_msg OK "Panel removal routine finished. Review any warnings above."
    pause
}

# ==================== 6. PHPMYADMIN ====================
phpmyadmin_tool() {
    show_header "PHPMYADMIN"

    run_remote_script "$PHPMYADMIN_URL" "phpMyAdmin Tool"
    pause
}

# ==================== MAIN MENU ====================
main_menu() {
    while true; do
        clear


        echo "██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗"
        echo "██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║"
        echo "██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║"
        echo "██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║"
        echo "██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║"
        echo "╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝"
        echo
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}           ${BOLD}${WHITE}PRITAM PTERODACTYL CONTROL CENTER${NC}          ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"

        if panel_exists; then
            echo -e "${CYAN}║${NC}  Panel Status : ${GREEN}${BOLD}INSTALLED ✔${NC}                            ${CYAN}║${NC}"
        elif [[ -d "$PANEL_DIR" ]]; then
            echo -e "${CYAN}║${NC}  Panel Status : ${YELLOW}INCOMPLETE / CHECK FILES${NC}               ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC}  Panel Status : ${RED}${BOLD}NOT INSTALLED ✘${NC}                        ${CYAN}║${NC}"
        fi

        echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} Install Panel       ${GRAY}Fresh Installation${NC}             ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[2]${NC} User Management     ${GRAY}Add Admin / User${NC}                ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GOLD}[3]${NC} Update Panel        ${GRAY}Choose Release${NC}                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${BLUE}[4]${NC} Domain & SSL        ${GRAY}Domain / HTTPS${NC}                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${RED}[5]${NC} Uninstall Panel     ${GRAY}Remove Panel Data${NC}               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${PURPLE}[6]${NC} phpMyAdmin          ${GRAY}Database Tool${NC}                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${WHITE}[0] Exit${NC}                                               ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -ne "${BOLD}${GREEN}  PRITAM@PANEL ${CYAN}➜ ${NC}"
        read -r choice

        case "$choice" in
            1) install_ptero ;;
            2) create_user ;;
            3) update_panel ;;
            4) domain_ssl ;;
            5) uninstall_ptero ;;
            6) phpmyadmin_tool ;;
            0) clear; exit 0 ;;
            *) status_msg ERR "Invalid option."; sleep 1 ;;
        esac
    done
}

# ==================== START ====================
if ! require_root; then
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    status_msg ERR "curl is required. Install it before using this tool."
    exit 1
fi

main_menu
