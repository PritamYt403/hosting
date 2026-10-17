
#!/usr/bin/env bash

PURPLE='\033[1;35m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

get_value() {
    if command -v "$1" >/dev/null 2>&1; then
        shift
        "$@" 2>/dev/null || echo "Unavailable"
    else
        echo "Unavailable"
    fi
}

show_status() {
    clear
    echo -e "${PURPLE}"
    cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       _ _     _
      | (_)   | |
      | |_ ___| |__  _ __  _   _
  _   | | / __| '_ \| '_ \| | | |
 | |__| | \__ \ | | | | | | |_| |
  \____/|_|___/_| |_|_| |_|\__,_|
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║               SYSTEM STATUS                  ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo -e "${RESET}"

    host="Unavailable"
    if [[ -r /etc/hostname ]]; then
        host="$(cat /etc/hostname)"
    elif command -v hostname >/dev/null 2>&1; then
        host="$(hostname 2>/dev/null || echo Unavailable)"
    fi

    user_name="${USER:-$(id -un 2>/dev/null || echo Unknown)}"
    directory="${PWD:-Unknown}"
    system="$(uname -srm 2>/dev/null || echo Unavailable)"

    uptime_text="Unavailable"
    if [[ -r /proc/uptime ]]; then
        seconds="${SECONDS:-0}"
        read -r uptime_seconds _ </proc/uptime
        if [[ "$uptime_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            total=${uptime_seconds%.*}
            days=$((total / 86400))
            hours=$(((total % 86400) / 3600))
            mins=$(((total % 3600) / 60))
            uptime_text="${days}d ${hours}h ${mins}m"
        fi
    elif command -v uptime >/dev/null 2>&1; then
        uptime_text="$(uptime 2>/dev/null || echo Unavailable)"
    fi

    memory="Unavailable"
    if [[ -r /proc/meminfo ]]; then
        read -r mem_total mem_available < <(
            awk '
                /^MemTotal:/ { total=$2 }
                /^MemAvailable:/ { available=$2 }
                END { print total, available }
            ' /proc/meminfo
        )
        if [[ "${mem_total:-0}" -gt 0 ]]; then
            used=$((mem_total - ${mem_available:-0}))
            memory="$(awk -v u="$used" -v t="$mem_total" \
                'BEGIN { printf "%.1fGi / %.1fGi", u/1048576, t/1048576 }')"
        fi
    fi

    disk="Unavailable"
    if command -v df >/dev/null 2>&1; then
        disk="$(df -hP . 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
        disk="${disk:-Unavailable}"
    fi

    cpu="Unavailable"
    if [[ -r /proc/cpuinfo ]]; then
        cpu="$(awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)"
        cpu="${cpu:-Unavailable}"
    fi

    printf "║  • Hostname:    %-32.32s║\n" "$host"
    printf "║  • User:        %-32.32s║\n" "$user_name"
    printf "║  • Directory:   %-32.32s║\n" "$directory"
    printf "║  • System:      %-32.32s║\n" "$system"
    printf "║  • Uptime:      %-32.32s║\n" "$uptime_text"
    printf "║  • Memory:      %-32.32s║\n" "$memory"
    printf "║  • Disk:        %-32.32s║\n" "$disk"
    printf "║  • CPU:         %-32.32s║\n" "$cpu"

    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${RESET}"
    echo
    read -rp "Press Enter to continue..." _
}

show_status
