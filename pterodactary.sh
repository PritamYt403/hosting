
#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════
#              PRITAM PANEL INSTALLER
#                  Professional Edition
# ═══════════════════════════════════════════════════════════

set -Eeuo pipefail

# ── PRITAM NEON THEME ─────────────────────────────────────
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
BLUE='\033[38;5;39m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;220m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'
NC='\033[0m'

LINE="${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

GITHUB_REPO="pterodactyl/panel"
PHP_VERSION="8.3"
PANEL_DIR="/var/www/pterodactyl"

# ── UI HELPERS ────────────────────────────────────────────
show_banner() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
 ____  ____  ___ _____ _   _   __  __
|  _ \|  _ \|_ _|_   _| \ | | |  \/  |
| |_) | |_) || |  | | |  \| | | |\/| |
|  __/|  _ < | |  | | | |\  | | |  | |
|_|   |_| \_\___| |_| |_| \_| |_|  |_|

EOF
    echo -e "${WHITE}          PRITAM PANEL INSTALLER${NC}"
    echo -e "${GRAY}        Pterodactyl Deployment Tool${NC}"
    echo -e "$LINE"
}

ok() {
    echo -e "  ${GREEN}✔${NC} $*"
}

info() {
    echo -e "  ${CYAN}➜${NC} $*"
}

warn() {
    echo -e "  ${GOLD}⚠${NC} $*"
}

fail() {
    echo -e "\n  ${RED}✖ ERROR:${NC} $*" >&2
    exit 1
}

step() {
    echo
    echo -e "$LINE"
    echo -e "  ${PURPLE}◆${NC} ${WHITE}$*${NC}"
    echo -e "$LINE"
}

# ── ERROR HANDLER ─────────────────────────────────────────
trap 'echo -e "\n${RED}Installation failed near line $LINENO.${NC} Check the error above."' ERR

# ── INPUT HELPERS ─────────────────────────────────────────
ask() {
    local label="$1"
    local default="$2"
    local result

    while true; do
        echo -ne "  ${PURPLE}•${NC} ${WHITE}${label}${NC} ${GRAY}[${default}]${NC}\n  ${GRAY}└─>${NC} "
        IFS= read -r result || true
        result="${result:-$default}"

        if [[ -n "$result" ]]; then
            REPLY="$result"
            return 0
        fi
    done
}

ask_secret() {
    local label="$1"
    local result

    while true; do
        echo -ne "  ${PURPLE}•${NC} ${WHITE}${label}${NC}\n  ${GRAY}└─>${NC} "
        IFS= read -r -s result || true
        echo

        if [[ ${#result} -ge 12 ]]; then
            REPLY="$result"
            return 0
        fi

        warn "Password must contain at least 12 characters."
    done
}

# ── REQUIREMENTS ──────────────────────────────────────────
[[ $EUID -eq 0 ]] || fail "Run this installer as root."

command -v apt-get >/dev/null 2>&1 ||
    fail "This installer requires Ubuntu or Debian."

command -v lsb_release >/dev/null 2>&1 ||
    apt-get update && apt-get install -y lsb-release

OS="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
CODENAME="$(lsb_release -cs)"

case "$OS" in
    ubuntu|debian) ;;
    *) fail "Unsupported operating system: $OS" ;;
esac

# ── START ─────────────────────────────────────────────────
show_banner

echo -e "\n  ${WHITE}Configure your new Pterodactyl Panel${NC}\n"

ask "Panel domain (without https://)" "panel.example.com"
DOMAIN="${REPLY,,}"

[[ "$DOMAIN" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] ||
    fail "Invalid domain format."

[[ "$DOMAIN" == *.* ]] ||
    fail "Enter a complete domain name."

ask "Administrator email" "admin@example.com"
EMAIL="$REPLY"

[[ "$EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] ||
    fail "Invalid email address."

ask "Administrator username" "admin"
USERNAME="$REPLY"

[[ "$USERNAME" =~ ^[a-zA-Z0-9_.-]+$ ]] ||
    fail "Username contains unsupported characters."

ask_secret "Administrator password (12+ characters)"
ADMIN_PASSWORD="$REPLY"

# Generate a database password using safe SQL characters.
DB_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40 || true)"
[[ ${#DB_PASS} -ge 32 ]] || fail "Could not generate database password."

# ── RELEASE SELECTOR ──────────────────────────────────────
step "Fetching available Panel releases"

RELEASE_JSON="$(curl -fsSL --retry 3 \
    "https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=20")" ||
    fail "Could not retrieve GitHub releases."

mapfile -t VERSIONS < <(
    python3 -c '
import json, sys
for r in json.load(sys.stdin):
    if not r.get("prerelease", False) and not r.get("draft", False):
        tag = r.get("tag_name", "")
        if tag:
            print(tag)
' <<<"$RELEASE_JSON"
)

if [[ ${#VERSIONS[@]} -eq 0 ]]; then
    fail "No stable releases were found."
fi

for i in "${!VERSIONS[@]}"; do
    printf "  ${GRAY}%2d.${NC} ${WHITE}%s${NC}\n" \
        "$((i + 1))" "${VERSIONS[$i]}"
done

echo
echo -ne "  ${PURPLE}•${NC} Select release ${GRAY}[1 = latest]${NC}: "
IFS= read -r VERSION_CHOICE || true
VERSION_CHOICE="${VERSION_CHOICE:-1}"

[[ "$VERSION_CHOICE" =~ ^[0-9]+$ ]] ||
    fail "Please enter a release number."

(( VERSION_CHOICE >= 1 && VERSION_CHOICE <= ${#VERSIONS[@]} )) ||
    fail "Release number is out of range."

PANEL_VERSION="${VERSIONS[$((VERSION_CHOICE - 1))]}"

# ── CONFIGURATION REVIEW ──────────────────────────────────
step "Review configuration"

echo -e "  ${GRAY}Operating system :${NC} $OS ($CODENAME)"
echo -e "  ${GRAY}Domain           :${NC} $DOMAIN"
echo -e "  ${GRAY}Admin email      :${NC} $EMAIL"
echo -e "  ${GRAY}Admin username   :${NC} $USERNAME"
echo -e "  ${GRAY}Panel release    :${NC} $PANEL_VERSION"
echo -e "  ${GRAY}PHP version      :${NC} $PHP_VERSION"
echo -e "  ${GRAY}Database password:${NC} auto-generated"
echo -e "  ${GRAY}SMTP             :${NC} configure separately if needed"

echo
echo -e "  ${GOLD}Make sure your domain points to this server's public IP.${NC}"
echo -e "  ${GOLD}Ports 80 and 443 must be reachable for HTTPS setup.${NC}"
echo
echo -ne "  ${CYAN}Start installation?${NC} ${WHITE}[y/N]${NC}: "
IFS= read -r CONFIRM || true

[[ "$CONFIRM" =~ ^[Yy]$ ]] ||
    fail "Installation cancelled."

# ── BASE PACKAGES ─────────────────────────────────────────
step "Installing system dependencies"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    curl ca-certificates gnupg unzip git tar sudo \
    lsb-release python3 openssl cron mariadb-server nginx \
    redis-server certbot python3-certbot-nginx

# ── PHP REPOSITORY ─────────────────────────────────────────
step "Preparing PHP repository"

if [[ "$OS" == "ubuntu" ]]; then
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
else
    install -d -m 0755 /usr/share/keyrings
    curl -fsSL https://packages.sury.org/php/apt.gpg |
        gpg --dearmor --yes -o /usr/share/keyrings/sury-php.gpg

    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" \
        >/etc/apt/sources.list.d/sury-php.list
fi

apt-get update

# ── PHP ───────────────────────────────────────────────────
step "Installing PHP ${PHP_VERSION}"

apt-get install -y \
    "php${PHP_VERSION}-cli" \
    "php${PHP_VERSION}-fpm" \
    "php${PHP_VERSION}-common" \
    "php${PHP_VERSION}-mysql" \
    "php${PHP_VERSION}-mbstring" \
    "php${PHP_VERSION}-bcmath" \
    "php${PHP_VERSION}-xml" \
    "php${PHP_VERSION}-zip" \
    "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-gd" \
    "php${PHP_VERSION}-intl" \
    "php${PHP_VERSION}-redis" \
    "php${PHP_VERSION}-sqlite3"

systemctl enable --now mariadb redis-server cron
systemctl enable --now "php${PHP_VERSION}-fpm"

# ── COMPOSER ──────────────────────────────────────────────
step "Installing Composer"

if ! command -v composer >/dev/null 2>&1; then
    COMPOSER_SETUP="$(mktemp)"
    curl -fsSL https://getcomposer.org/installer -o "$COMPOSER_SETUP"
    php "$COMPOSER_SETUP" --install-dir=/usr/local/bin --filename=composer
    rm -f "$COMPOSER_SETUP"
fi

composer --version
ok "Composer is ready"

# ── DOWNLOAD PANEL ────────────────────────────────────────
step "Downloading Pterodactyl ${PANEL_VERSION}"

if [[ -e "$PANEL_DIR" ]]; then
    fail "$PANEL_DIR already exists. Back up and move it before reinstalling."
fi

mkdir -p "$PANEL_DIR"
TMP_ARCHIVE="$(mktemp)"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${PANEL_VERSION}/panel.tar.gz"

curl -fL --retry 3 "$DOWNLOAD_URL" -o "$TMP_ARCHIVE"
tar -tzf "$TMP_ARCHIVE" >/dev/null
tar -xzf "$TMP_ARCHIVE" -C "$PANEL_DIR"
rm -f "$TMP_ARCHIVE"

cd "$PANEL_DIR"
[[ -f artisan ]] || fail "Panel archive is invalid: artisan was not found."
[[ -f .env.example ]] || fail "Panel archive does not contain .env.example."

# ── DATABASE ──────────────────────────────────────────────
step "Configuring MariaDB"

mariadb <<SQL
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

# ── ENVIRONMENT ───────────────────────────────────────────
step "Configuring Panel environment"

cp .env.example .env

set_env() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" .env; then
        sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
        printf '%s=%s\n' "$key" "$value" >>.env
    fi
}

set_env APP_URL "https://${DOMAIN}"
set_env APP_ENV production
set_env APP_DEBUG false
set_env DB_CONNECTION mysql
set_env DB_HOST 127.0.0.1
set_env DB_PORT 3306
set_env DB_DATABASE panel
set_env DB_USERNAME pterodactyl
set_env DB_PASSWORD "$DB_PASS"
set_env CACHE_DRIVER redis
set_env SESSION_DRIVER redis
set_env QUEUE_CONNECTION redis
set_env REDIS_HOST 127.0.0.1
set_env APP_NAME '"Pritam Panel"'

# ── PANEL DEPENDENCIES ────────────────────────────────────
step "Installing Panel dependencies"

export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --optimize-autoloader --no-interaction

php artisan key:generate --force
php artisan migrate --seed --force

# ── PERMISSIONS AND SCHEDULER ─────────────────────────────
step "Configuring permissions and scheduler"

chown -R www-data:www-data "$PANEL_DIR"
chmod -R 755 storage bootstrap/cache

cat >/etc/cron.d/pterodactyl <<EOF
* * * * * www-data cd ${PANEL_DIR} && /usr/bin/php artisan schedule:run >> /dev/null 2>&1
EOF
chmod 0644 /etc/cron.d/pterodactyl

# ── NGINX HTTP CONFIG ─────────────────────────────────────
step "Configuring Nginx"

cat >/etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root ${PANEL_DIR}/public;
    index index.php;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \\n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\\.ht {
        deny all;
    }
}
EOF

ln -sfn /etc/nginx/sites-available/pterodactyl.conf \
    /etc/nginx/sites-enabled/pterodactyl.conf

rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

# ── HTTPS ──────────────────────────────────────────────────
step "Requesting HTTPS certificate"

if certbot --nginx --non-interactive --agree-tos \
    --redirect --email "$EMAIL" -d "$DOMAIN"; then
    ok "HTTPS certificate installed"
else
    warn "Let's Encrypt setup failed."
    warn "Check DNS and ports 80/443, then run: certbot --nginx -d $DOMAIN"
fi

# ── QUEUE WORKER ──────────────────────────────────────────
step "Configuring queue worker"

cat >/etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pritam Panel Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=${PANEL_DIR}
Restart=always
ExecStart=/usr/bin/php ${PANEL_DIR}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pteroq.service

# ── PANEL SETTINGS ────────────────────────────────────────
step "Finalizing Panel"

cd "$PANEL_DIR"
php artisan view:clear
php artisan config:clear
php artisan cache:clear
php artisan config:cache
php artisan queue:restart
chown -R www-data:www-data "$PANEL_DIR"

# ── ADMIN USER ────────────────────────────────────────────
step "Creating administrator account"

php artisan p:user:make \
    --email="$EMAIL" \
    --username="$USERNAME" \
    --name-first="Pritam" \
    --name-last="Admin" \
    --password="$ADMIN_PASSWORD" \
    --admin=1

# ── COMPLETE ──────────────────────────────────────────────
clear
echo -e "$LINE"
echo -e "  ${GREEN}✔ INSTALLATION FINISHED${NC}"
echo -e "$LINE"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://${DOMAIN}${NC}"
echo -e "  ${GRAY}Username  :${NC} ${WHITE}${USERNAME}${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}${EMAIL}${NC}"
echo -e "  ${GOLD}Password  :${NC} ${WHITE}(the password you entered)${NC}"
echo -e "$LINE"
echo -e "  ${CYAN}PRITAM PANEL INSTALLER${NC}"
echo -e "  ${GRAY}SMTP email delivery must be configured separately.${NC}"
echo -e "$LINE"

unset ADMIN_PASSWORD DB_PASS
