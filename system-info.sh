
#!/usr/bin/env bash

# ═══════════════════════════════════════════
#       PRITAM VPS SYSTEM MONITOR
#              Made by Pritam
# ═══════════════════════════════════════════

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

line() {
    printf "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

get_hostname() {
    hostname 2>/dev/null || uname -n
}

get_uptime() {
    if [[ -r /proc/uptime ]]; then
        local seconds total days hours mins
        read -r seconds _ < /proc/uptime
        total=${seconds%.*}
        days=$((total / 86400))
        hours=$(((total % 86400) / 3600))
        mins=$(((total % 3600) / 60))
        printf "%dd %dh %dm" "$days" "$hours" "$mins"
    else
        echo "Unavailable"
    fi
}

get_memory() {
    if command -v free >/dev/null 2>&1; then
        free -h | awk '
            /^Mem:/ {
                printf "Used: %s / Total: %s | Available: %s",
                    $3, $2, $7
            }
        '
    else
        echo "Unavailable"
    fi
}

get_memory_percent() {
    free -b 2>/dev/null | awk '
        /^Mem:/ {
            if ($2 > 0)
                printf "%d", ($3 * 100 / $2)
            else
                print 0
        }
    '
}

get_disk() {
    df -hP / 2>/dev/null |
        awk 'NR==2 {print $3 " used / " $2 " total | " $4 " available (" $5 ")"}'
}

get_disk_percent() {
    df -P / 2>/dev/null |
        awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

get_cpu() {
    if [[ -r /proc/cpuinfo ]]; then
        awk -F: '/model name/ {
            sub(/^[ \t]+/, "", $2)
            print $2
            exit
        }' /proc/cpuinfo
    else
        uname -m
    fi
}

get_cpu_cores() {
    nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo
}

get_os() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-Linux}"
    else
        uname -s
    fi
}

progress_bar() {
    local value="${1:-0}" width=20 filled i color
    [[ "$value" =~ ^[0-9]+$ ]] || value=0
    (( value > 100 )) && value=100

    filled=$((value * width / 100))
    color="$GREEN"

    if (( value >= 80 )); then
        color="$RED"
    elif (( value >= 60 )); then
        color="$YELLOW"
    fi

    printf "${color}["
    for ((i=0; i<width; i++)); do
        if ((i < filled)); then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "]${RESET} %s%%" "$value"
}

show_status() {
    clear 2>/dev/null || true

    echo -e "${PURPLE}"
    cat <<'EOF'
  ██████╗ ██████╗ ██╗████████╗ █████╗ ███╗   ███╗
  ██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗████╗ ████║
  ██████╔╝██████╔╝██║   ██║   ███████║██╔████╔██║
  ██╔═══╝ ██╔══██╗██║   ██║   ██╔══██║██║╚██╔╝██║
  ██║     ██║  ██║██║   ██║   ██║  ██║██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "${WHITE}              VPS SYSTEM MONITOR${RESET}"
    echo -e "${CYAN}                 Made By Pritam${RESET}"
    echo

    line
    printf "${CYAN}  Scanning system information...${RESET}\n\n"

    local host user_name directory os kernel uptime_text
    local memory disk cpu cores mem_percent disk_percent

    host="$(get_hostname)"
    user_name="$(id -un 2>/dev/null || echo Unknown)"
    directory="$PWD"
    os="$(get_os)"
    kernel="$(uname -r)"
    uptime_text="$(get_uptime)"
    memory="$(get_memory)"
    disk="$(get_disk)"
    cpu="$(get_cpu)"
    cores="$(get_cpu_cores)"
    mem_percent="$(get_memory_percent)"
    disk_percent="$(get_disk_percent)"

    echo -e "${CYAN}  ╔══════════════════ SYSTEM OVERVIEW ══════════════════╗${RESET}"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Hostname" "$host"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "User" "$user_name"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Directory" "$directory"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Operating System" "$os"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Kernel" "$kernel"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Uptime" "$uptime_text"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "CPU Cores" "$cores"
    echo -e "${CYAN}  ╚═════════════════════════════════════════════════════╝${RESET}"

    echo
    echo -e "${PURPLE}  ┌────────────── RESOURCE MONITOR ─────────────────────┐${RESET}"
    echo -e "${PURPLE}  │${RESET} ${WHITE}RAM (from free -h)${RESET}"
    echo -e "${PURPLE}  │${RESET} $memory"
    echo -e "${PURPLE}  │${RESET} $(progress_bar "${mem_percent:-0}")"
    echo -e "${PURPLE}  │${RESET}"
    echo -e "${PURPLE}  │${RESET} ${WHITE}Root Disk (from df -h /)${RESET}"
    echo -e "${PURPLE}  │${RESET} $disk"
    echo -e "${PURPLE}  │${RESET} $(progress_bar "${disk_percent:-0}")"
    echo -e "${PURPLE}  └─────────────────────────────────────────────────────┘${RESET}"

    echo
    echo -e "${CYAN}  ┌────────────────── CPU DETAILS ──────────────────────┐${RESET}"
    printf "  ${CYAN}│${RESET} %-52.52s ${CYAN}│${RESET}\n" "$cpu"
    echo -e "${CYAN}  └─────────────────────────────────────────────────────┘${RESET}"

    echo
    line
    echo -e "${GREEN}  ✓ PRITAM System Monitor completed.${RESET}"
    echo -e "${GRAY}  RAM: free -h | Disk: df -h /${RESET}"
    echo
    read -rp "  Press Enter to return to menu..." _
}

show_status
