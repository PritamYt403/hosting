
#!/usr/bin/env bash

# ═════════════════════════════════════════════════════
#          PRITAM DATABASE MANAGEMENT TOOL
#             MySQL / MariaDB Edition
# ═════════════════════════════════════════════════════

set -o pipefail

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'
BOLD='\033[1m'

DB_CLIENT=""
DB_TYPE=""
ADMIN_USER="root"
ADMIN_PASSWORD=""
AUTH_MODE=""

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

line() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

header() {
    clear 2>/dev/null || true
    echo
    echo -e "${PURPLE}${BOLD}"
    cat <<'EOF'
  ____        _        _           _
 |  _ \  __ _| |_ __ _| |__   __ _| |_ ___
 | | | |/ _` | __/ _` | '_ \ / _` | __/ __|
 | |_| | (_| | || (_| | |_) | (_| | |_\__ \
 |____/ \__,_|\__\__,_|_.__/ \__,_|\__|___/
EOF
    echo -e "${RESET}"
    echo -e "       ${ORANGE}${BOLD}PRITAM DATABASE MANAGER${RESET}"
    echo -e "       ${CYAN}MySQL / MariaDB Setup${RESET}"
    line
    echo
}

detect_database() {
    DB_CLIENT=""
    DB_TYPE=""

    if command -v mariadb >/dev/null 2>&1; then
        DB_CLIENT="$(command -v mariadb)"
        DB_TYPE="MariaDB-compatible client"
    elif command -v mysql >/dev/null 2>&1; then
        DB_CLIENT="$(command -v mysql)"
        DB_TYPE="MySQL-compatible client"
    fi

    [[ -n "$DB_CLIENT" ]]
}

detect_server_service() {
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet mariadb 2>/dev/null; then
            echo "mariadb"
            return 0
        elif systemctl is-active --quiet mysql 2>/dev/null; then
            echo "mysql"
            return 0
        elif systemctl is-active --quiet mysqld 2>/dev/null; then
            echo "mysqld"
            return 0
        fi
    fi
    return 1
}

sql_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\'/\'\'}"
    printf '%s' "$value"
}

valid_identifier() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]{0,63}$ ]]
}

db_query() {
    if [[ "$AUTH_MODE" == "socket" ]]; then
        "$DB_CLIENT" -u "$ADMIN_USER" --batch --skip-column-names "$@"
    else
        MYSQL_PWD="$ADMIN_PASSWORD" \
            "$DB_CLIENT" -u "$ADMIN_USER" --batch --skip-column-names "$@"
    fi
}

connect_admin() {
    local result

    echo -e "${CYAN}Checking database administrator access...${RESET}"

    # First try local root/socket authentication.
    if [[ $EUID -eq 0 ]] &&
       "$DB_CLIENT" -u root -Nse "SELECT 1" >/dev/null 2>&1; then
        ADMIN_USER="root"
        ADMIN_PASSWORD=""
        AUTH_MODE="socket"
        echo -e "${GREEN}Administrator access verified (local authentication).${RESET}"
        return 0
    fi

    read -rp "Database administrator username [root]: " ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-root}"

    if [[ ! "$ADMIN_USER" =~ ^[a-zA-Z0-9_.@-]{1,80}$ ]]; then
        echo -e "${RED}Invalid administrator username.${RESET}"
        return 1
    fi

    read -rsp "Database administrator password: " ADMIN_PASSWORD
    echo

    AUTH_MODE="password"

    if db_query -e "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}Administrator access verified.${RESET}"
        return 0
    fi

    ADMIN_PASSWORD=""
    echo -e "${RED}Could not authenticate to the database server.${RESET}"
    echo -e "${YELLOW}Check the username, password and server status.${RESET}"
    return 1
}

install_mariadb() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run this installer as root.${RESET}"
        return 1
    fi

    if detect_database; then
        echo -e "${GREEN}Database client already exists: ${DB_CLIENT}${RESET}"
        return 0
    fi

    echo -e "${YELLOW}MySQL/MariaDB client is missing.${RESET}"
    echo "This will install the MariaDB server and client packages."
    read -rp "Install MariaDB now? [y/N]: " confirm
    case "$confirm" in
        y|Y|yes|YES|Yes) ;;
        *)
            echo -e "${YELLOW}Installation cancelled. No changes made.${RESET}"
            return 1
            ;;
    esac

    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update || return 1
        apt-get install -y mariadb-server mariadb-client || return 1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y mariadb-server mariadb || return 1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y mariadb-server mariadb || return 1
    else
        echo -e "${RED}Unsupported package manager.${RESET}"
        echo "Supported systems: Ubuntu/Debian, Fedora/RHEL, and compatible dnf/yum systems."
        echo "Install MariaDB server/client with your OS package manager, then retry."
        return 1
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl enable --now mariadb 2>/dev/null; then
            :
        elif systemctl enable --now mysql 2>/dev/null; then
            :
        else
            echo -e "${RED}Packages installed, but the database service could not be started.${RESET}"
            echo "Check: systemctl status mariadb --no-pager"
            return 1
        fi
    else
        echo -e "${YELLOW}Packages installed, but systemd is unavailable; start MariaDB using your OS service manager.${RESET}"
    fi

    if ! detect_database; then
        echo -e "${RED}Installation finished, but no database client was detected. Not marking success.${RESET}"
        return 1
    fi

    echo -e "${GREEN}${BOLD}MariaDB client detected: ${DB_CLIENT}${RESET}"
    "$DB_CLIENT" --version || return 1
    return 0
}

prepare_database() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Please run as root: sudo bash database.sh${RESET}"
        return 1
    fi

    if ! detect_database; then
        install_mariadb || return 1
        detect_database || {
            echo -e "${RED}Database client is still unavailable after installation.${RESET}"
            return 1
        }
    fi

    echo -e "${GREEN}Detected client: ${DB_CLIENT}${RESET}"
    echo -e "${GRAY}Type: ${DB_TYPE}${RESET}"

    if ! detect_server_service >/dev/null; then
        echo -e "${YELLOW}No active database service detected.${RESET}"
        echo "Checking whether the server is reachable..."

        if ! "$DB_CLIENT" -u root -Nse "SELECT 1" >/dev/null 2>&1; then
            echo -e "${RED}Database server is not reachable with local root authentication.${RESET}"
            echo "Start your existing MySQL/MariaDB service, then retry."
            return 1
        fi
    fi

    connect_admin || return 1
}

create_database_user() {
    local db_name db_user db_password
    local db_host host_sql user_sql password_sql db_sql
    local sql

    echo
    line
    echo -e "${CYAN}${BOLD}CREATE DATABASE AND USER${RESET}"
    line

    read -rp "New database name: " db_name
    if ! valid_identifier "$db_name"; then
        echo -e "${RED}Invalid database name. Use letters, numbers and underscores.${RESET}"
        return 1
    fi

    read -rp "New database username: " db_user
    if ! valid_identifier "$db_user"; then
        echo -e "${RED}Invalid username. Use letters, numbers and underscores.${RESET}"
        return 1
    fi

    read -rsp "Password for ${db_user}: " db_password
    echo

    if [[ ${#db_password} -lt 12 ]]; then
        echo -e "${RED}Use a password of at least 12 characters.${RESET}"
        db_password=""
        return 1
    fi

    echo
    echo -e "${YELLOW}Remote connection access is disabled by default.${RESET}"
    echo "For remote access, enter a trusted client IP address."
    echo "Leave empty to allow local connections only."
    read -rp "Trusted client IP (optional): " db_host

    if [[ -n "$db_host" ]]; then
        if [[ ! "$db_host" =~ ^[0-9a-fA-F:.]+$ ]] ||
           [[ "$db_host" == *".."* ]]; then
            echo -e "${RED}Invalid IP address format. Remote access cancelled.${RESET}"
            db_password=""
            return 1
        fi
    else
        db_host="localhost"
    fi

    db_sql="$(sql_escape "$db_name")"
    user_sql="$(sql_escape "$db_user")"
    password_sql="$(sql_escape "$db_password")"
    host_sql="$(sql_escape "$db_host")"

    echo
    echo -e "${CYAN}Creating database and granting permissions...${RESET}"

    sql="
CREATE DATABASE IF NOT EXISTS \`${db_sql}\`;
CREATE USER IF NOT EXISTS '${user_sql}'@'localhost' IDENTIFIED BY '${password_sql}';
ALTER USER '${user_sql}'@'localhost' IDENTIFIED BY '${password_sql}';
GRANT ALL PRIVILEGES ON \`${db_sql}\`.* TO '${user_sql}'@'localhost';
"

    if [[ "$db_host" != "localhost" ]]; then
        sql+="
CREATE USER IF NOT EXISTS '${user_sql}'@'${host_sql}' IDENTIFIED BY '${password_sql}';
ALTER USER '${user_sql}'@'${host_sql}' IDENTIFIED BY '${password_sql}';
GRANT ALL PRIVILEGES ON \`${db_sql}\`.* TO '${user_sql}'@'${host_sql}';
"
    fi

    if ! printf '%s\n' "$sql" | db_query; then
        echo -e "${RED}Database operation failed. No success message will be shown.${RESET}"
        db_password=""
        sql=""
        return 1
    fi

    # Verify that the database exists and the account has its grant.
    if ! db_query -e "SHOW DATABASES LIKE '${db_sql}'" 2>/dev/null |
        grep -Fxq "$db_name"; then
        echo -e "${RED}Verification failed: database was not found.${RESET}"
        db_password=""
        sql=""
        return 1
    fi

    if ! db_query -e "SHOW GRANTS FOR '${user_sql}'@'localhost'" >/dev/null 2>&1; then
        echo -e "${RED}Verification failed: user or grants were not found.${RESET}"
        db_password=""
        sql=""
        return 1
    fi

    echo
    echo -e "${GREEN}${BOLD}DATABASE SETUP VERIFIED${RESET}"
    echo -e "${WHITE}Database : ${db_name}${RESET}"
    echo -e "${WHITE}Username : ${db_user}${RESET}"
    echo -e "${WHITE}Host     : localhost${RESET}"

    if [[ "$db_host" != "localhost" ]]; then
        echo -e "${WHITE}Remote host: ${db_host}${RESET}"
        echo -e "${YELLOW}Ensure the server bind address and firewall allow only trusted clients.${RESET}"
    fi

    echo -e "${GREEN}Database exists and the user grants were verified.${RESET}"

    db_password=""
    password_sql=""
    sql=""
    unset MYSQL_PWD
}

database_status() {
    echo
    line
    echo -e "${CYAN}${BOLD}DATABASE STATUS${RESET}"
    line

    if ! detect_database; then
        echo -e "${RED}No MySQL/MariaDB client found.${RESET}"
        return 1
    fi

    echo -e "${GREEN}Client: ${DB_CLIENT}${RESET}"

    local service
    if service="$(detect_server_service)"; then
        echo -e "${GREEN}Active service: ${service}${RESET}"
    else
        echo -e "${YELLOW}No active database service detected by systemd.${RESET}"
    fi

    if "$DB_CLIENT" -u root -Nse "SELECT VERSION()" 2>/dev/null; then
        echo -e "${GREEN}Local root connection verified.${RESET}"
    else
        echo -e "${YELLOW}Could not verify local root authentication.${RESET}"
        echo "Use Create Database / User to try administrator authentication."
    fi
}

main() {
    local choice

    while true; do
        header

        echo -e "${CYAN}  [1]${WHITE} Detect Database Installation"
        echo -e "${GREEN}  [2]${WHITE} Create Database & User"
        echo -e "${ORANGE}  [3]${WHITE} Check Database Status"
        echo -e "${YELLOW}  [4]${WHITE} Install MariaDB Server + Client"
        echo -e "${RED}  [0]${WHITE} Exit"
        line

        read -rp "$(echo -e "${PURPLE}PRITAM ${CYAN}» ${RESET}")" choice

        case "$choice" in
            1)
                prepare_database
                pause
                ;;
            2)
                if prepare_database; then
                    create_database_user
                fi
                pause
                ;;
            3)
                database_status
                pause
                ;;
            4)
                install_mariadb
                pause
                ;;
            0)
                echo -e "${GREEN}Exiting PRITAM Database Manager.${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Choose 0-4.${RESET}"
                sleep 1
                ;;
        esac
    done
}

main
