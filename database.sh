#!/usr/bin/env bash
# PRITAM MySQL / MariaDB Database Setup
set -Eeuo pipefail

PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'
RED='\033[1;31m'; YELLOW='\033[1;33m'; WHITE='\033[1;37m'
GRAY='\033[0;37m'; ORANGE='\033[38;5;208m'; RESET='\033[0m'; BOLD='\033[1m'
DB_CLIENT=""; DB_SERVICE=""; ADMIN_USER="root"; ADMIN_PASSWORD=""; AUTH_MODE="socket"

line() { echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
finish() { echo; read -rp "Press Enter to continue..." _ || true; }
cleanup() { unset ADMIN_PASSWORD DB_PASSWORD MYSQL_PWD 2>/dev/null || true; }
trap cleanup EXIT

header() {
  clear 2>/dev/null || true
  echo -e "${PURPLE}${BOLD}"
  cat <<'BANNER'
  ____        _        _           _
 |  _ \  __ _| |_ __ _| |__   __ _| |_ ___
 | | | |/ _` | __/ _` | '_ \ / _` | __/ __|
 | |_| | (_| | || (_| | |_) | (_| | ||  __/
 |____/ \__,_|\__\__,_|_.__/ \__,_|\__\___|
BANNER
  echo -e "${RESET}       ${ORANGE}${BOLD}PRITAM DATABASE SETUP${RESET}"
  echo -e "       ${CYAN}MySQL / MariaDB Edition${RESET}"
  line
  echo
}

fail() { echo -e "${RED}✖ $*${RESET}"; return 1; }

find_client() {
  if command -v mariadb >/dev/null 2>&1; then DB_CLIENT="$(command -v mariadb)"
  elif command -v mysql >/dev/null 2>&1; then DB_CLIENT="$(command -v mysql)"
  else DB_CLIENT=""; fi
  [[ -n "$DB_CLIENT" ]]
}

install_mariadb() {
  [[ $EUID -eq 0 ]] || { fail "Run as root: sudo bash database.sh"; return 1; }
  echo -e "${YELLOW}MySQL/MariaDB client is missing.${RESET}"
  read -rp "Install MariaDB server and client now? [y/N]: " answer
  case "$answer" in y|Y|yes|YES|Yes) ;; *) echo "Installation cancelled."; return 1 ;; esac

  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update || { fail "Package list update failed."; return 1; }
    apt-get install -y mariadb-server mariadb-client || { fail "MariaDB installation failed."; return 1; }
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y mariadb-server mariadb || { fail "MariaDB installation failed."; return 1; }
  elif command -v yum >/dev/null 2>&1; then
    yum install -y mariadb-server mariadb || { fail "MariaDB installation failed."; return 1; }
  else
    fail "Unsupported package manager. Install MariaDB server/client manually."; return 1
  fi

  find_client || { fail "Packages ran, but no mysql/mariadb client was found."; return 1; }
  echo -e "${GREEN}Client installed: ${DB_CLIENT}${RESET}"
}

detect_service() {
  if command -v systemctl >/dev/null 2>&1; then
    for svc in mariadb mysql mysqld; do
      if systemctl cat "$svc" >/dev/null 2>&1; then DB_SERVICE="$svc"; return 0; fi
    done
  fi
  DB_SERVICE=""
  return 1
}

start_database() {
  detect_service || { fail "Cannot find a systemd MySQL/MariaDB service."; return 1; }
  if ! systemctl is-active --quiet "$DB_SERVICE"; then
    echo -e "${CYAN}Starting ${DB_SERVICE} service...${RESET}"
    systemctl enable --now "$DB_SERVICE" || { fail "Could not start ${DB_SERVICE}. Check systemctl status ${DB_SERVICE}."; return 1; }
  fi
  systemctl is-active --quiet "$DB_SERVICE" || { fail "Database service is not active."; return 1; }
  echo -e "${GREEN}Service active: ${DB_SERVICE}${RESET}"
}

sql_escape() {
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//\'/\'\'}"
  printf '%s' "$v"
}

valid_identifier() { [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]{0,63}$ ]]; }

db_query() {
  if [[ "$AUTH_MODE" == "socket" ]]; then
    "$DB_CLIENT" -u "$ADMIN_USER" --batch --skip-column-names "$@"
  else
    MYSQL_PWD="$ADMIN_PASSWORD" "$DB_CLIENT" -u "$ADMIN_USER" --batch --skip-column-names "$@"
  fi
}

connect_admin() {
  echo -e "${CYAN}Checking database administrator access...${RESET}"
  if [[ $EUID -eq 0 ]] && "$DB_CLIENT" -u root -Nse 'SELECT 1' >/dev/null 2>&1; then
    ADMIN_USER=root; ADMIN_PASSWORD=""; AUTH_MODE=socket
    echo -e "${GREEN}Local administrator authentication verified.${RESET}"
    return 0
  fi

  read -rp "Database administrator username [root]: " ADMIN_USER
  ADMIN_USER="${ADMIN_USER:-root}"
  read -rsp "Database administrator password: " ADMIN_PASSWORD; echo
  AUTH_MODE=password
  if db_query -e 'SELECT 1' >/dev/null 2>&1; then
    echo -e "${GREEN}Administrator authentication verified.${RESET}"; return 0
  fi
  ADMIN_PASSWORD=""
  fail "Database administrator login failed. No user/database was created."
  return 1
}

setup_database() {
  local db_user db_name DB_PASSWORD db_user_sql db_name_sql pass_sql
  local remote_ip remote_sql sql conf_file conf_dir

  [[ $EUID -eq 0 ]] || { fail "Run this script as root."; return 1; }
  header
  echo -e "${CYAN}${BOLD}Running: MySQL / MariaDB Database Setup${RESET}"
  line

  if ! find_client; then
    install_mariadb || return 1
    find_client || { fail "Database client is still missing. Stopping."; return 1; }
  fi
  echo -e "${GREEN}Detected client: ${DB_CLIENT}${RESET}"

  start_database || return 1
  "$DB_CLIENT" --version || { fail "Client version check failed."; return 1; }
  connect_admin || return 1

  echo
  read -rp "Enter new database username: " db_user
  valid_identifier "$db_user" || { fail "Invalid username. Use letters, numbers and underscores; first character must be a letter or underscore."; return 1; }
  read -rp "Database name [${db_user}]: " db_name
  db_name="${db_name:-$db_user}"
  valid_identifier "$db_name" || { fail "Invalid database name."; return 1; }
  read -rsp "Enter password for ${db_user} (minimum 12 characters): " DB_PASSWORD; echo
  [[ ${#DB_PASSWORD} -ge 12 ]] || { DB_PASSWORD=""; fail "Password must contain at least 12 characters."; return 1; }

  echo
  echo -e "${YELLOW}Remote access is optional and restricted to one trusted IP.${RESET}"
  read -rp "Trusted remote client IP (blank = local-only): " remote_ip
  if [[ -n "$remote_ip" ]]; then
    if ! python3 - "$remote_ip" <<'PY' >/dev/null 2>&1
import ipaddress, sys
ipaddress.ip_address(sys.argv[1])
PY
    then DB_PASSWORD=""; fail "Invalid IPv4/IPv6 address. Remote access not configured."; return 1; fi
  fi

  db_user_sql="$(sql_escape "$db_user")"
  db_name_sql="$(sql_escape "$db_name")"
  pass_sql="$(sql_escape "$DB_PASSWORD")"
  sql="CREATE DATABASE IF NOT EXISTS \`${db_name_sql}\`;
CREATE USER IF NOT EXISTS '${db_user_sql}'@'localhost' IDENTIFIED BY '${pass_sql}';
ALTER USER '${db_user_sql}'@'localhost' IDENTIFIED BY '${pass_sql}';
GRANT ALL PRIVILEGES ON \`${db_name_sql}\`.* TO '${db_user_sql}'@'localhost';"
  if [[ -n "$remote_ip" ]]; then
    remote_sql="$(sql_escape "$remote_ip")"
    sql+="
CREATE USER IF NOT EXISTS '${db_user_sql}'@'${remote_sql}' IDENTIFIED BY '${pass_sql}';
ALTER USER '${db_user_sql}'@'${remote_sql}' IDENTIFIED BY '${pass_sql}';
GRANT ALL PRIVILEGES ON \`${db_name_sql}\`.* TO '${db_user_sql}'@'${remote_sql}';"
  fi

  echo -e "${CYAN}Creating database and user...${RESET}"
  if ! printf '%s\n' "$sql" | db_query; then
    DB_PASSWORD=""; sql=""; fail "MySQL/MariaDB rejected the setup. No success message will be shown."; return 1
  fi

  if ! db_query -e "SHOW DATABASES LIKE '${db_name_sql}'" 2>/dev/null | grep -Fxq "$db_name"; then
    DB_PASSWORD=""; sql=""; fail "Verification failed: database does not exist."; return 1
  fi
  if ! db_query -e "SHOW GRANTS FOR '${db_user_sql}'@'localhost'" >/dev/null 2>&1; then
    DB_PASSWORD=""; sql=""; fail "Verification failed: user grants were not found."; return 1
  fi
  if [[ -n "$remote_ip" ]] && ! db_query -e "SHOW GRANTS FOR '${db_user_sql}'@'${remote_sql}'" >/dev/null 2>&1; then
    DB_PASSWORD=""; sql=""; fail "Local database was created, but remote grant verification failed."; return 1
  fi

  # Remote bind configuration is only changed when a trusted IP was explicitly supplied.
  if [[ -n "$remote_ip" ]]; then
    if [[ -d /etc/mysql/mariadb.conf.d ]]; then
      conf_dir=/etc/mysql/mariadb.conf.d; conf_file="$conf_dir/99-pritam-remote.cnf"
    elif [[ -d /etc/my.cnf.d ]]; then
      conf_dir=/etc/my.cnf.d; conf_file="$conf_dir/99-pritam-remote.cnf"
    elif [[ -d /etc/mysql/conf.d ]]; then
      conf_dir=/etc/mysql/conf.d; conf_file="$conf_dir/99-pritam-remote.cnf"
    else
      echo -e "${YELLOW}Could not locate a standard MariaDB config directory; remote network access may need manual configuration.${RESET}"
      conf_file=""
    fi

    if [[ -n "$conf_file" ]]; then
      if [[ ! -e "$conf_file" ]]; then
        printf '[mysqld]\nbind-address = 0.0.0.0\n' > "$conf_file" || { fail "Could not write remote config."; return 1; }
      else
        echo -e "${YELLOW}Existing remote config left unchanged: ${conf_file}${RESET}"
      fi
      if ! systemctl restart "$DB_SERVICE"; then
        fail "Database restart failed after remote config change. Check service logs before continuing."; return 1
      fi
      systemctl is-active --quiet "$DB_SERVICE" || { fail "Database service is not active after restart."; return 1; }
      if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi 'Status: active'; then
        ufw allow from "$remote_ip" to any port 3306 proto tcp || { fail "Could not add UFW rule for trusted IP."; return 1; }
        echo -e "${GREEN}UFW rule added for ${remote_ip} only.${RESET}"
      else
        echo -e "${YELLOW}UFW is not active; configure your VPS/cloud firewall to allow TCP 3306 from ${remote_ip} only.${RESET}"
      fi
    fi
  fi

  # Final connection + grants verification after optional restart.
  if ! db_query -e "SHOW DATABASES LIKE '${db_name_sql}'" 2>/dev/null | grep -Fxq "$db_name"; then
    DB_PASSWORD=""; sql=""; fail "Final verification failed. Setup is not reported as successful."; return 1
  fi

  echo
  echo -e "${GREEN}${BOLD}✓ DATABASE SETUP VERIFIED${RESET}"
  echo -e "${WHITE}Database : ${db_name}${RESET}"
  echo -e "${WHITE}Username : ${db_user}${RESET}"
  echo -e "${WHITE}Host     : localhost${RESET}"
  if [[ -n "$remote_ip" ]]; then
    echo -e "${WHITE}Remote IP: ${remote_ip}${RESET}"
    echo -e "${YELLOW}Only connect remotely from the trusted IP; ensure your cloud firewall also restricts port 3306.${RESET}"
  else
    echo -e "${WHITE}Remote   : Disabled (local-only)${RESET}"
  fi
  echo -e "${GREEN}Database and grants were verified successfully.${RESET}"
  DB_PASSWORD=""; ADMIN_PASSWORD=""; sql=""; unset MYSQL_PWD
  return 0
}

if ! setup_database; then
  echo
  echo -e "${RED}${BOLD}✖ DATABASE SETUP FAILED${RESET}"
  echo -e "${YELLOW}Check the error above. Success was not reported.${RESET}"
  finish
  exit 1
fi
finish
