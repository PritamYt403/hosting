#!/usr/bin/env bash

# ══════════════════════════════════════════════════════════════
#                 PRITAM PTERODACTYL INSTALLER
#                    Professional Edition
# ══════════════════════════════════════════════════════════════

set -Eeuo pipefail
umask 077

# ── Neon Theme ────────────────────────────────────────────────
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

REPO="pterodactyl/panel"
PHP_VERSION="8.3"
PANEL_DIR="/var/www/pterodactyl"
DB_NAME="panel"
DB_USER="pterodactyl"

# ── UI Helpers ────────────────────────────────────────────────
line() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

step() {
    echo
    echo -e "${PURPLE}➜ ${WHITE}$*${NC}"
}

ok() {
    echo -e "${GREEN}✔ $*${NC}"
}

warn() {
    echo -e "${GOLD}⚠ $*${NC}"
}

die() {
    echo -e "${RED}✖ $*${NC}" >&2
    exit 1
}

pause() {
    echo
    read -rp "Press Enter to continue..." _ || true
}

show_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    cat <<'EOF'
██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗
██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║
██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║
██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║
██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║
╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${NC}"
    echo -e "             ${WHITE}PRITAM PTERODACTYL INSTALLER${NC}"
    echo -e "              ${PURPLE}Professional Edition${NC}"
    line
    echo
}

# ── Input Validation ──────────────────────────────────────────
ask_value() {
    local prompt="$1"
    local default="$2"
    local result

    while true; do
        read -rp "$(echo -e "${CYAN}•${NC} ${WHITE}${prompt}${NC} [${default}]: ")" result || die "Input cancelled."
        result="${result:-$default}"

        if [[ -n "$result" ]]; then
            REPLY="$result"
            return 0
        fi
    done
}

ask_secret() {
    local prompt="$1"
    local result

    while true; do
        read -rsp "$(echo -e "${CYAN}•${NC} ${WHITE}${prompt}${NC}: ")" result || die "Password input cancelled."
        echo

        if [[ ${#result} -ge 12 ]]; then
            REPLY="$result"
            return 0
        fi

        warn "Password must contain at least 12 characters. Try again."
        result=""
    done
}

validate_domain() {
    [[ "$1" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]
}

validate_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_username() {
    [[ "$1" =~ ^[A-Za-z0-9_]{3,32}$ ]]
}

# ── System Checks ─────────────────────────────────────────────
check_system() {
    [[ $EUID -eq 0 ]] || die "Run this script as root."
    command -v curl >/dev/null 2>&1 || die "curl is required."
    command -v python3 >/dev/null 2>&1 || die "python3 is required."
    command -v openssl >/dev/null 2>&1 || die "openssl is required."

    [[ -r /etc/os-release ]] || die "Cannot detect operating system."
    # shellcheck disable=SC1091
    source /etc/os-release

    case "${ID:-}" in
        ubuntu|debian) ;;
        *) die "Supported operating systems: Ubuntu or Debian." ;;
    esac

    if [[ -f "${PANEL_DIR}/artisan" ]]; then
        die "Pterodactyl Panel already exists at ${PANEL_DIR}. Refusing to overwrite it."
    fi

    if [[ -e "${PANEL_DIR}" ]]; then
        [[ -d "${PANEL_DIR}" ]] || die "${PANEL_DIR} exists and is not a directory."
        [[ -z "$(find "${PANEL_DIR}" -mindepth 1 -maxdepth 1 -print -quit)" ]] ||
            die "${PANEL_DIR} is not empty. Back it up and inspect it first."
    fi
}

# ── Version Selector ──────────────────────────────────────────
select_version() {
    step "Fetching official Pterodactyl releases"

    local json
    json="$(mktemp)"
    local choices=()

    if ! curl -fsSL --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/${REPO}/releases?per_page=20" \
        -o "$json"; then
        rm -f "$json"
        die "Could not fetch releases from GitHub."
    fi

    mapfile -t choices < <(
        python3 -c '
import json,sys
try:
    data=json.load(open(sys.argv[1]))
    for r in data:
        tag=r.get("tag_name","")
        if tag and not r.get("prerelease",False) and not r.get("draft",False):
            print(tag)
except Exception:
    sys.exit(1)
' "$json"
    ) || {
        rm -f "$json"
        die "Could not parse release information."
    }

    rm -f "$json"

    ((${#choices[@]} > 0)) || die "No stable releases were returned."

    echo
    local i
    for i in "${!choices[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "${choices[$i]}"
    done

    echo
    echo "  0) Cancel installation"
    echo

    while true; do
        read -rp "Choose release [1-${#choices[@]}]: " selection || die "Input cancelled."

        if [[ "$selection" == "0" ]]; then
            exit 0
        elif [[ "$selection" =~ ^[0-9]+$ ]] &&
             ((selection >= 1 && selection <= ${#choices[@]})); then
            VERSION="${choices[$((selection - 1))]}"
            break
        fi

        warn "Select a listed version."
    done

    ok "Selected release: ${VERSION}"
}

# ── Configuration ─────────────────────────────────────────────
collect_config() {
    echo -e "${CYAN}CONFIGURATION${NC}"
    line

    while true; do
        ask_value "Panel domain (DNS must point to this VPS)" "panel.example.com"
        DOMAIN="$REPLY"
        validate_domain "$DOMAIN" && break
        warn "Enter a valid domain name."
    done

    while true; do
        ask_value "Administrator email" "admin@example.com"
        EMAIL="$REPLY"
        validate_email "$EMAIL" && break
        warn "Enter a valid email address."
    done

    while true; do
        ask_value "Administrator username" "pritam"
        USERNAME="$REPLY"
        validate_username "$USERNAME" && break
        warn "Use 3-32 letters, numbers, or underscores."
    done

    ask_secret "Administrator password (12+ characters)"
    ADMIN_PASSWORD="$REPLY"

    select_version

    echo
    line
    echo -e "${WHITE}REVIEW CONFIGURATION${NC}"
    echo "  Domain   : ${DOMAIN}"
    echo "  Email    : ${EMAIL}"
    echo "  Username : ${USERNAME}"
    echo "  Version  : ${VERSION}"
    echo "  Password : [hidden]"
    line

    local confirm
    read -rp "Start installation? Type YES: " confirm || die "Input cancelled."
    [[ "$confirm" == "YES" ]] || die "Installation cancelled."
}

# ── Dependencies ──────────────────────────────────────────────
install_dependencies() {
    step "Installing system dependencies"

    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y \
        ca-certificates curl gnupg unzip git tar sudo \
        lsb-release openssl python3 cron mariadb-server \
        nginx redis-server certbot python3-certbot-nginx \
        software-properties-common

    if [[ "${ID}" == "ubuntu" ]]; then
        add-apt-repository -y ppa:ondrej/php
    else
        install -d -m 0755 /usr/share/keyrings
        curl -fsSL https://packages.sury.org/php/apt.gpg |
            gpg --dearmor --yes -o /usr/share/keyrings/sury-php.gpg

        echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${VERSION_CODENAME} main" \
            > /etc/apt/sources.list.d/sury-php.list
    fi

    apt-get update

    apt-get install -y \
        "php${PHP_VERSION}" \
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
        "php${PHP_VERSION}-redis"

    systemctl enable --now mariadb nginx redis-server "php${PHP_VERSION}-fpm" cron

    ok "Dependencies installed"
}

# ── Composer ───────────────────────────────────────────────────
install_composer() {
    step "Installing Composer"

    if command -v composer >/dev/null 2>&1; then
        ok "Composer already installed"
        return
    fi

    local installer expected actual
    installer="$(mktemp)"
    expected="$(mktemp)"

    curl -fsSL https://composer.github.io/installer.sig -o "$expected"
    curl -fsSL https://getcomposer.org/installer -o "$installer"

    actual="$(php -r "echo hash_file('sha384', '$installer');")"
    local wanted
    wanted="$(cat "$expected")"

    if [[ "$actual" != "$wanted" ]]; then
        rm -f "$installer" "$expected"
        die "Composer installer checksum verification failed."
    fi

    php "$installer" --install-dir=/usr/local/bin --filename=composer
    rm -f "$installer" "$expected"

    ok "Composer installed"
}

# ── Database Setup ────────────────────────────────────────────
setup_database() {
    step "Configuring local MariaDB"

    DB_PASS="$(openssl rand -hex 24)"

    mariadb -e "CREATE DATABASE \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
    mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';"
    mariadb -e "FLUSH PRIVILEGES;"

    ok "Database and restricted local database account created"
}

# ── Download Panel ─────────────────────────────────────────────
download_panel() {
    step "Downloading Pterodactyl ${VERSION}"

    mkdir -p "$PANEL_DIR"
    cd "$PANEL_DIR"

    local archive
    archive="$(mktemp)"

    curl -fL --retry 3 \
        "https://github.com/${REPO}/releases/download/${VERSION}/panel.tar.gz" \
        -o "$archive"

    tar -tzf "$archive" >/dev/null ||
        die "Panel archive validation failed."

    tar -xzf "$archive" -C "$PANEL_DIR"
    rm -f "$archive"

    [[ -f .env.example ]] || die "Downloaded release is missing .env.example."

    cp .env.example .env
    chmod -R 755 storage bootstrap/cache

    ok "Panel files downloaded"
}

# ── Environment ────────────────────────────────────────────────
configure_environment() {
    step "Configuring Panel environment"

    cd "$PANEL_DIR"

    # Write values using PHP so special characters in passwords
    # do not break the .env file.
    export PRITAM_DOMAIN="$DOMAIN"
    export PRITAM_DB_NAME="$DB_NAME"
    export PRITAM_DB_USER="$DB_USER"
    export PRITAM_DB_PASS="$DB_PASS"

    php <<'PHP'
<?php
$file = '.env';
$env = file_get_contents($file);

$values = [
    'APP_URL' => 'https://' . getenv('PRITAM_DOMAIN'),
    'APP_ENV' => 'production',
    'APP_DEBUG' => 'false',
    'APP_ENVIRONMENT_ONLY' => 'false',
    'DB_CONNECTION' => 'mysql',
    'DB_HOST' => '127.0.0.1',
    'DB_PORT' => '3306',
    'DB_DATABASE' => getenv('PRITAM_DB_NAME'),
    'DB_USERNAME' => getenv('PRITAM_DB_USER'),
    'DB_PASSWORD' => getenv('PRITAM_DB_PASS'),
];

foreach ($values as $key => $value) {
    $line = $key . '=' . $value;
    $pattern = '/^' . preg_quote($key, '/') . '=.*$/m';

    if (preg_match($pattern, $env)) {
        $env = preg_replace($pattern, $line, $env);
    } else {
        $env .= "\n" . $line . "\n";
    }
}

file_put_contents($file, $env);
PHP

    unset PRITAM_DB_PASS DB_PASS

    ok "Environment configured"
}

# ── Application Setup ──────────────────────────────────────────
setup_application() {
    step "Installing PHP dependencies"

    cd "$PANEL_DIR"
    COMPOSER_ALLOW_SUPERUSER=1 composer install \
        --no-dev --optimize-autoloader --no-interaction

    php artisan key:generate --force
    php artisan migrate --seed --force

    chown -R www-data:www-data "$PANEL_DIR"
    chmod -R 755 storage bootstrap/cache

    # Install the scheduler entry without duplicating it.
    local cron_entry
    cron_entry="* * * * * php ${PANEL_DIR}/artisan schedule:run >> /dev/null 2>&1"

    (crontab -u www-data -l 2>/dev/null | grep -vF "${PANEL_DIR}/artisan schedule:run" || true
     echo "$cron_entry") | crontab -u www-data -

    ok "Application configured"
}

# ── Nginx ──────────────────────────────────────────────────────
configure_nginx() {
    step "Configuring Nginx"

    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
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

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

    ln -sfn /etc/nginx/sites-available/pterodactyl.conf \
        /etc/nginx/sites-enabled/pterodactyl.conf

    nginx -t
    systemctl reload nginx

    ok "Nginx configured"
}

# ── HTTPS ──────────────────────────────────────────────────────
configure_ssl() {
    step "Requesting HTTPS certificate"

    echo "The domain must resolve to this VPS and ports 80/443 must be reachable."

    if certbot --nginx \
        --non-interactive \
        --agree-tos \
        --redirect \
        --email "$EMAIL" \
        -d "$DOMAIN"; then
        ok "HTTPS certificate configured"
    else
        warn "Automatic HTTPS setup failed."
        warn "Check DNS, firewall rules, and run certbot manually after fixing them."
        warn "The Panel may not be reachable securely until HTTPS is configured."
    fi
}

# ── Queue Worker ───────────────────────────────────────────────
configure_queue() {
    step "Configuring queue worker"

    cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=PRITAM Pterodactyl Queue Worker
After=redis-server.service mariadb.service
Requires=redis-server.service

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

    ok "Queue worker enabled"
}

# ── Admin Account ──────────────────────────────────────────────
create_admin() {
    step "Creating administrator account"

    cd "$PANEL_DIR"

    php artisan p:user:make \
        --email="$EMAIL" \
        --username="$USERNAME" \
        --name-first="Pritam" \
        --name-last="Admin" \
        --password="$ADMIN_PASSWORD" \
        --admin=1

    unset ADMIN_PASSWORD

    ok "Administrator account created"
}

# ── Final Report ───────────────────────────────────────────────
final_report() {
    cd "$PANEL_DIR"

    php artisan view:clear
    php artisan config:clear
    php artisan cache:clear
    php artisan config:cache
    php artisan queue:restart

    chown -R www-data:www-data "$PANEL_DIR"

    clear
    line
    echo -e "${GREEN}             PRITAM PANEL INSTALLATION FINISHED${NC}"
    line
    echo
    echo -e "  ${WHITE}Panel URL :${NC} https://${DOMAIN}"
    echo -e "  ${WHITE}Username  :${NC} ${USERNAME}"
    echo -e "  ${WHITE}Email     :${NC} ${EMAIL}"
    echo -e "  ${WHITE}Password  :${NC} Not displayed for security"
    echo
    warn "Save your credentials securely."
    warn "Configure outgoing mail in .env before relying on email features."
    line
}

# ── Main ───────────────────────────────────────────────────────
main() {
    show_banner

    check_system
    collect_config

    install_dependencies
    install_composer
    setup_database
    download_panel
    configure_environment
    setup_application
    configure_nginx
    configure_ssl
    configure_queue
    create_admin
    final_report
}

main "$@"

