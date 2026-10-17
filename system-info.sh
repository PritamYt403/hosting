
#!/usr/bin/env bash

# ═══════════════════════════════════════════════
#           PRITAM VPS SYSTEM MONITOR
#                  Made by Pritam
# ═══════════════════════════════════════════════

PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

line() {
    printf "${GRAY}%s${RESET}\n" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

loading_animation() {
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    for frame in "${frames[@]}"; do
        printf "\r${CYAN}  %s Initializing PRITAM System Monitor...${RESET}" "$frame"
        sleep 0.07
    done

    printf "\r${GREEN}  ✓ System scan completed.                         ${RESET}\n\n"
}

get_hostname() {
    if [[ -r /etc/hostname ]]; then
        cat /etc/hostname
    else
        uname -n 2>/dev/null || echo "Unavailable"
    fi
}

get_uptime() {
    if [[ -r /proc/uptime ]]; then
        local seconds total days hours mins
        read -r seconds _ < /proc/uptime
        total=${seconds%.*}

        [[ "$total" =~ ^[0-9]+$ ]] || {
            echo "Unavailable"
            return
        }

        days=$((total / 86400))
        hours=$(((total % 86400) / 3600))
        mins=$(((total % 3600) / 60))

        printf "%dd %dh %dm" "$days" "$hours" "$mins"
    else
        echo "Unavailable"
    fi
}

get_memory() {
    if [[ ! -r /proc/meminfo ]]; then
        echo "Unavailable"
        return
    fi

    awk '
        /^MemTotal:/ { total=$2 }
        /^MemAvailable:/ { available=$2 }
        END {
            if (total > 0) {
                used=total-available
                printf "%.1f GiB / %.1f GiB",
                    used/1048576, total/1048576
            } else {
                print "Unavailable"
            }
        }
    ' /proc/meminfo
}

get_memory_percent() {
    if [[ -r /proc/meminfo ]]; then
        awk '
            /^MemTotal:/ { total=$2 }
            /^MemAvailable:/ { available=$2 }
            END {
                if (total > 0)
                    printf "%.0f", ((total-available)/total)*100
                else
                    print 0
            }
        ' /proc/meminfo
    else
        echo 0
    fi
}

get_disk() {
    if command -v df >/dev/null 2>&1; then
        df -hP . 2>/dev/null |
            awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}'
    else
        echo "Unavailable"
    fi
}

get_disk_percent() {
    if command -v df >/dev/null 2>&1; then
        df -P . 2>/dev/null |
            awk 'NR==2 {gsub(/%/, "", $5); print $5}'
    else
        echo 0
    fi
}

get_cpu() {
    if [[ -r /proc/cpuinfo ]]; then
        awk -F: '
            /model name/ {
                sub(/^[ \t]+/, "", $2)
                print $2
                exit
            }
        ' /proc/cpuinfo
    elif [[ -r /proc/device-tree/model ]]; then
        tr -d '\0' < /proc/device-tree/model
    else
        uname -m
    fi
}

get_cpu_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc 2>/dev/null || echo "Unknown"
    else
        grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "Unknown"
    fi
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
    local value="${1:-0}"
    local width=20
    local filled i color

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
        if (( i < filled )); then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "]${RESET} %s%%" "$value"
}

show_status() {
    clear 2>/dev/null || true

    echo
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
    echo -e "${CYAN}                Made By - Pritam${RESET}"
    echo

    line
    loading_animation

    local host user_name directory system uptime_text
    local memory disk cpu os cores mem_percent disk_percent

    host="$(get_hostname)"
    user_name="${USER:-$(id -un 2>/dev/null || echo Unknown)}"
    directory="${PWD:-Unknown}"
    system="$(uname -srm 2>/dev/null || echo Unavailable)"
    uptime_text="$(get_uptime)"
    memory="$(get_memory)"
    disk="$(get_disk)"
    cpu="$(get_cpu)"
    os="$(get_os)"
    cores="$(get_cpu_cores)"
    mem_percent="$(get_memory_percent)"
    disk_percent="$(get_disk_percent)"

    echo -e "${CYAN}  ╔══════════════════ SYSTEM OVERVIEW ══════════════════╗${RESET}"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Hostname" "$host"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "User" "$user_name"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Directory" "$directory"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Operating System" "$os"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Kernel" "$system"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "Uptime" "$uptime_text"
    printf "  ${CYAN}║${RESET} ${WHITE}%-16s${RESET} %-36.36s ${CYAN}║${RESET}\n" "CPU Cores" "$cores"
    echo -e "${CYAN}  ╚═════════════════════════════════════════════════════╝${RESET}"

    echo
    echo -e "${PURPLE}  ┌────────────── RESOURCE MONITOR ─────────────────────┐${RESET}"
    echo -e "${PURPLE}  │${RESET} ${WHITE}Memory Usage${RESET}"
    echo -e "${PURPLE}  │${RESET} $memory"
    echo -e "${PURPLE}  │${RESET} $(progress_bar "$mem_percent")"
    echo -e "${PURPLE}  │${RESET}"
    echo -e "${PURPLE}  │${RESET} ${WHITE}Disk Usage (current filesystem)${RESET}"
    echo -e "${PURPLE}  │${RESET} $disk"
    echo -e "${PURPLE}  │${RESET} $(progress_bar "$disk_percent")"
    echo -e "${PURPLE}  └─────────────────────────────────────────────────────┘${RESET}"

    echo
    echo -e "${CYAN}  ┌────────────────── CPU DETAILS ──────────────────────┐${RESET}"
    printf "  ${CYAN}│${RESET} %-52.52s ${CYAN}│${RESET}\n" "$cpu"
    echo -e "${CYAN}  └─────────────────────────────────────────────────────┘${RESET}"

    echo
    line
    echo -e "${GREEN}  ✓ PRITAM System Monitor completed successfully.${RESET}"
    echo -e "${GRAY}  All values reflect the environment running this script.${RESET}"
    echo
    read -rp "  Press Enter to return to menu..." _
}

show_status
