#!/usr/bin/env bash
# Pritam Pterodactyl Control Center
# Traditional installer is fetched from the configured repository.
# Docker deployment uses the official Pterodactyl Panel container image.

set -u
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; WHITE='\033[1;37m'; RESET='\033[0m'
BASE_URL="https://raw.githubusercontent.com/PritamYt403/hosting/main/pterodactyl"
DOCKER_DIR="/opt/pritam-pterodactyl"

line(){ echo -e "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
pause_menu(){ echo; read -r -p "Press Enter to return..." _ || true; }
valid_domain(){ [[ "$1" =~ ^(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)\.)+[a-zA-Z]{2,63}$ ]]; }
valid_email(){ [[ "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; }
need_root(){ if [[ ${EUID:-$(id -u)} -ne 0 ]]; then echo -e "${RED}[!] Run this script as root (sudo -i).${RESET}"; return 1; fi; }
ask_admin(){
  read -r -p "Admin email: " user_email
  read -r -p "Confirm admin email: " email_confirm
  if [[ "$user_email" != "$email_confirm" ]] || ! valid_email "$user_email"; then echo -e "${RED}[!] Email invalid or does not match.${RESET}"; return 1; fi
  read -r -p "Admin username: " user_username
  read -r -p "Admin first name: " user_firstname
  read -r -p "Admin last name: " user_lastname
  read -r -s -p "Admin password: " user_password; echo
  read -r -s -p "Confirm admin password: " password_confirm; echo
  if [[ -z "$user_username" || -z "$user_firstname" || -z "$user_lastname" || -z "$user_password" || "$user_password" != "$password_confirm" ]]; then
    echo -e "${RED}[!] Required fields missing or passwords do not match.${RESET}"; unset user_password password_confirm; return 1
  fi
  unset email_confirm password_confirm
}
ask_domain(){
  read -r -p "Panel domain (e.g. panel.example.com, without https://): " FQDN
  FQDN="${FQDN,,}"
  if ! valid_domain "$FQDN"; then echo -e "${RED}[!] Enter a valid domain, not localhost or an IP address.${RESET}"; return 1; fi
  echo -e "${YELLOW}DNS A record for ${FQDN} must point to this VPS. Ports 80/443 must be reachable.${RESET}"
}

install_traditional(){
  need_root || { pause_menu; return 1; }
  command -v curl >/dev/null 2>&1 || { echo -e "${RED}[!] curl is required.${RESET}"; pause_menu; return 1; }
  echo; line; echo -e "${CYAN} TRADITIONAL PANEL INSTALLATION ${RESET}"; line
  ask_domain || { pause_menu; return 1; }
  ask_admin || { unset user_password; pause_menu; return 1; }
  local tmp status=0 panel_domain="$FQDN"
  tmp="$(mktemp)" || { echo -e "${RED}[!] Cannot create temporary file.${RESET}"; unset user_password; pause_menu; return 1; }
  email="$user_email"
  export FQDN email user_email user_username user_firstname user_lastname user_password
  export CONFIGURE_LETSENCRYPT=true ASSUME_SSL=false CONFIGURE_FIREWALL=true
  echo -e "${CYAN}[*] Downloading traditional installer...${RESET}"
  if curl -fsSL --connect-timeout 15 --retry 2 "$BASE_URL/pterodactary.sh" -o "$tmp" && [[ -s "$tmp" ]]; then bash "$tmp" || status=$?; else echo -e "${RED}[!] Download failed or file empty.${RESET}"; status=1; fi
  rm -f "$tmp"; unset email FQDN user_email user_username user_firstname user_lastname user_password CONFIGURE_LETSENCRYPT ASSUME_SSL CONFIGURE_FIREWALL
  if [[ $status -eq 0 ]]; then echo -e "${GREEN}[✓] Finished. Panel URL: https://${panel_domain}${RESET}"; else echo -e "${RED}[!] Installer exited with code $status.${RESET}"; fi
  pause_menu; return "$status"
}

install_docker(){
  need_root || { pause_menu; return 1; }
  echo; line; echo -e "${CYAN} DOCKER PANEL INSTALLATION ${RESET}"; line
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker is not installed. Install Docker Engine using the official convenience script?${RESET}"
    read -r -p "Type YES to install Docker: " docker_confirm
    if [[ "$docker_confirm" != "YES" ]]; then echo -e "${YELLOW}Cancelled.${RESET}"; pause_menu; return 1; fi
    command -v curl >/dev/null 2>&1 || { echo -e "${RED}[!] curl is required to install Docker.${RESET}"; pause_menu; return 1; }
    if ! curl -fsSL https://get.docker.com -o /tmp/pritam-get-docker.sh || ! bash /tmp/pritam-get-docker.sh; then rm -f /tmp/pritam-get-docker.sh; echo -e "${RED}[!] Docker installation failed.${RESET}"; pause_menu; return 1; fi
    rm -f /tmp/pritam-get-docker.sh
  fi
  if docker compose version >/dev/null 2>&1; then :; else echo -e "${RED}[!] Docker Compose plugin is missing. Install docker-compose-plugin and retry.${RESET}"; pause_menu; return 1; fi
  ask_domain || { pause_menu; return 1; }
  ask_admin || { unset user_password; pause_menu; return 1; }
  if [[ -e "$DOCKER_DIR/docker-compose.yml" || -e "$DOCKER_DIR/compose.yml" ]]; then
    echo -e "${RED}[!] Existing Docker panel config found at $DOCKER_DIR; refusing to overwrite it.${RESET}"; unset user_password; pause_menu; return 1
  fi
  if ss -ltn 2>/dev/null | grep -Eq ':(80|443)[[:space:]]'; then
    echo -e "${YELLOW}[!] A service may already be using port 80 or 443. Check before continuing.${RESET}"
    read -r -p "Continue anyway? Type YES: " port_confirm
    if [[ "$port_confirm" != "YES" ]]; then unset user_password; pause_menu; return 1; fi
  fi
  local db_password root_password status=0 tries
  db_password="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)"
  root_password="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40)"
  mkdir -p "$DOCKER_DIR"/{database,var,nginx,certs,logs}
  chmod 700 "$DOCKER_DIR"
  cat > "$DOCKER_DIR/docker-compose.yml" <<COMPOSE
services:
  database:
    image: mariadb:11
    restart: unless-stopped
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_DATABASE: panel
      MYSQL_USER: pterodactyl
      MYSQL_PASSWORD: "$db_password"
      MYSQL_ROOT_PASSWORD: "$root_password"
    volumes:
      - "$DOCKER_DIR/database:/var/lib/mysql"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 12
  cache:
    image: redis:alpine
    restart: unless-stopped
  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: unless-stopped
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_started
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "$DOCKER_DIR/var:/app/var"
      - "$DOCKER_DIR/nginx:/etc/nginx/http.d"
      - "$DOCKER_DIR/certs:/etc/letsencrypt"
      - "$DOCKER_DIR/logs:/app/storage/logs"
    environment:
      APP_URL: "https://$FQDN"
      APP_TIMEZONE: "UTC"
      APP_SERVICE_AUTHOR: "$user_email"
      LE_EMAIL: "$user_email"
      APP_ENV: production
      APP_ENVIRONMENT_ONLY: "false"
      DB_HOST: database
      DB_PORT: "3306"
      DB_DATABASE: panel
      DB_USERNAME: pterodactyl
      DB_PASSWORD: "$db_password"
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      QUEUE_DRIVER: redis
      REDIS_HOST: cache
      HASHIDS_LENGTH: 8
COMPOSE
  chmod 600 "$DOCKER_DIR/docker-compose.yml"
  echo -e "${CYAN}[*] Starting Docker containers. First start may take several minutes...${RESET}"
  if ! (cd "$DOCKER_DIR" && docker compose up -d); then echo -e "${RED}[!] Docker Compose failed. Logs: cd $DOCKER_DIR && docker compose logs${RESET}"; unset user_password; pause_menu; return 1; fi
  echo -e "${CYAN}[*] Waiting for Panel container...${RESET}"
  tries=0
  until (cd "$DOCKER_DIR" && docker compose ps --status running --services 2>/dev/null | grep -qx panel); do
    tries=$((tries+1)); if (( tries >= 30 )); then echo -e "${RED}[!] Panel container did not start. Check: cd $DOCKER_DIR && docker compose logs panel${RESET}"; unset user_password; pause_menu; return 1; fi
    sleep 5
  done
  echo -e "${YELLOW}[!] Waiting for panel initialization, then creating admin account...${RESET}"
  local admin_ok=false
  for attempt in $(seq 1 12); do
    if (cd "$DOCKER_DIR" && docker compose exec -T panel php artisan p:user:make --email="$user_email" --username="$user_username" --name-first="$user_firstname" --name-last="$user_lastname" --password="$user_password" --admin=1); then
      admin_ok=true
      break
    fi
    echo -e "${YELLOW}[*] Panel is not ready yet (${attempt}/12); retrying in 10 seconds...${RESET}"
    sleep 10
  done
  if [[ "$admin_ok" == true ]]; then
    echo -e "${GREEN}[✓] Docker Panel and admin account setup command completed.${RESET}"
    echo -e "${GREEN}Panel URL: https://${FQDN}${RESET}"
  else
    echo -e "${RED}[!] Containers are running, but automatic admin creation failed. After checking logs, run:${RESET}"
    echo "cd $DOCKER_DIR && docker compose exec panel php artisan p:user:make"
    status=1
  fi
  echo -e "${CYAN}Compose file: $DOCKER_DIR/docker-compose.yml${RESET}"
  unset user_password db_password root_password
  pause_menu; return "$status"
}

remove_panel(){
  need_root || { pause_menu; return 1; }
  echo; line; echo -e "${RED} PANEL REMOVAL ${RESET}"; line
  echo -e "${YELLOW}This can stop or remove your panel. Confirm carefully.${RESET}"
  read -r -p "Choose deployment: [1] Traditional [2] Docker [0] Cancel: " kind
  read -r -p "Type YES to confirm: " confirm
  [[ "$confirm" == "YES" ]] || { echo -e "${YELLOW}Removal cancelled.${RESET}"; pause_menu; return 0; }
  case "$kind" in
    1)
      local tmp status=0
      tmp="$(mktemp)" || { pause_menu; return 1; }
      if curl -fsSL --connect-timeout 15 "$BASE_URL/uninstall.sh" -o "$tmp" && [[ -s "$tmp" ]]; then bash "$tmp" || status=$?; else echo -e "${RED}[!] Could not download uninstall.sh.${RESET}"; status=1; fi
      rm -f "$tmp"; pause_menu; return "$status" ;;
    2)
      if [[ -f "$DOCKER_DIR/docker-compose.yml" ]]; then
        (cd "$DOCKER_DIR" && docker compose down) || { echo -e "${RED}[!] Docker removal failed.${RESET}"; pause_menu; return 1; }
        echo -e "${GREEN}Containers stopped and removed. Data/configs are preserved at $DOCKER_DIR.${RESET}"
      else echo -e "${YELLOW}[!] No Docker panel compose file found at $DOCKER_DIR.${RESET}"; fi
      ;;
    0) echo "Cancelled." ;;
    *) echo -e "${RED}[!] Invalid choice.${RESET}" ;;
  esac
  pause_menu
}

while true; do
  clear
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║              PRITAM PTERODACTYL CONTROL CENTER              ║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo; line; echo -e "${YELLOW}  CONTROL MODULES${RESET}"; line
  echo -e "  ${GREEN}[1]${WHITE} Traditional Panel Installation${RESET}"
  echo -e "  ${GREEN}[2]${WHITE} Docker Panel Installation${RESET}"
  echo -e "  ${RED}[3]${WHITE} Panel Removal (Traditional / Docker)${RESET}"
  echo -e "  ${RED}[0]${WHITE} Exit${RESET}"; line
  read -r -p "Select an option [0-3]: " choice || exit 0
  case "$choice" in
    1) install_traditional ;;
    2) install_docker ;;
    3) remove_panel ;;
    0) echo -e "${GREEN}Thanks for using Pritam Hosting Manager!${RESET}"; exit 0 ;;
    *) echo -e "${RED}[!] Invalid option.${RESET}"; sleep 1 ;;
  esac
done
