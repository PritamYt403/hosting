#!/bin/bash
set -euo pipefail

# =============================
# Enhanced Multi-VM Manager (Pure QEMU + Proxmox Version)
# =============================

# Function to display header
display_header() {
    clear
    cat << "EOF"
 ███████████                                                                        
░░███░░░░░███                                                                       
 ░███    ░███ ████████   ██████  █████ █████ █████████████    ██████  █████ █████   
 ░██████████ ░░███░░███ ███░░███░░███ ░░███ ░░███░░███░░███  ███░░███░░███ ░░███    
 ░███░░░░░░   ░███ ░░░ ░███ ░███ ░░░█████░   ░███ ░███ ░███ ░███ ░███ ░░░█████░     
 ░███         ░███     ░███ ░███  ███░░░███  ░███ ░███ ░███ ░███ ░███  ███░░░███    
 █████        █████    ░░██████  █████ █████ █████░███ █████░░██████  █████ █████   
░░░░░        ░░░░░      ░░░░░░  ░░░░░ ░░░░░ ░░░░░ ░░░ ░░░░░  ░░░░░░  ░░░░░ ░░░░░    
                                                                
        🔧 Pure QEMU + Proxmox Integration 🔧                                      
                                                                                                       
EOF
    echo
}

# Initialize paths and logging
VM_DIR="${VM_DIR:-$HOME/vms}"
PROXMOX_DIR="${PROXMOX_DIR:-$HOME/proxmox}"
LOG_FILE="$VM_DIR/vm_manager.log"
mkdir -p "$VM_DIR" "$PROXMOX_DIR"

# Configuration file
CONFIG_FILE="$HOME/.vm_manager.conf"

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" <<EOF
# VM Manager Configuration
VM_DIR="$VM_DIR"
PROXMOX_DIR="$PROXMOX_DIR"
PROXMOX_HOST="${PROXMOX_HOST:-}"
PROXMOX_USER="${PROXMOX_USER:-}"
PROXMOX_REALM="${PROXMOX_REALM:-pam}"
PROXMOX_NODE="${PROXMOX_NODE:-}"
STORAGE="${STORAGE:-local}"
EOF
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Function to configure Proxmox
configure_proxmox() {
    print_status "INFO" "🔧 Configuring Proxmox connection"
    
    read -p "$(print_status "INPUT" "🌐 Proxmox Host/IP (e.g., 192.168.1.100): ")" PROXMOX_HOST
    read -p "$(print_status "INPUT" "👤 Proxmox Username (e.g., root@pam): ")" PROXMOX_USER
    read -p "$(print_status "INPUT" "🔑 Proxmox Password: ")" -s PROXMOX_PASS
    echo
    read -p "$(print_status "INPUT" "🏷️  Proxmox Node name (e.g., pve): ")" PROXMOX_NODE
    read -p "$(print_status "INPUT" "💾 Storage name (e.g., local-lvm): ")" STORAGE
    
    # Test connection
    if command -v pvesh &>/dev/null; then
        if PASSWORD="$PROXMOX_PASS" pvesh get /nodes/$PROXMOX_NODE/status --no-header 2>/dev/null; then
            print_status "SUCCESS" "✅ Proxmox connection successful"
        else
            print_status "ERROR" "❌ Failed to connect to Proxmox"
            return 1
        fi
    fi
    
    save_config
}

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Function to display colored output with emojis
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "INFO") echo -e "\033[1;34m📋 [INFO]\033[0m $message"; log_message "INFO" "$message" ;;
        "WARN") echo -e "\033[1;33m⚠️  [WARN]\033[0m $message"; log_message "WARN" "$message" ;;
        "ERROR") echo -e "\033[1;31m❌ [ERROR]\033[0m $message"; log_message "ERROR" "$message" ;;
        "SUCCESS") echo -e "\033[1;32m✅ [SUCCESS]\033[0m $message"; log_message "SUCCESS" "$message" ;;
        "INPUT") echo -e "\033[1;36m🎯 [INPUT]\033[0m $message" ;;
        *) echo "[$type] $message"; log_message "$type" "$message" ;;
    esac
}

# Function to show progress indicator
show_progress() {
    local pid=$1
    local msg=$2
    local spin='-\|/'
    local i=0
    
    echo -n "$msg "
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${msg} ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${msg} ✅\n"
}

# Function to check if image file is locked
check_image_lock() {
    local img_file=$1
    local vm_name=$2
    
    # Check if QEMU is already using this image
    if lsof "$img_file" 2>/dev/null | grep -q qemu-system; then
        print_status "WARN" "🔒 Image file $img_file is already in use by another QEMU process"
        
        # Find the process ID
        local pid=$(lsof "$img_file" 2>/dev/null | grep qemu-system | awk '{print $2}' | head -1)
        if [[ -n "$pid" ]]; then
            print_status "INFO" "🔍 Process ID using the image: $pid"
            
            # Check if it's our own VM
            if ps -p "$pid" -o cmd= | grep -q "$vm_name"; then
                print_status "INFO" "🤔 This appears to be the same VM already running"
                read -p "$(print_status "INPUT" "🔄 Kill existing process and restart? (y/N): ")" kill_choice
                if [[ "$kill_choice" =~ ^[Yy]$ ]]; then
                    kill "$pid"
                    sleep 2
                    if kill -0 "$pid" 2>/dev/null; then
                        kill -9 "$pid"
                        print_status "WARN" "⚠️  Forcefully terminated process $pid"
                    fi
                    return 0
                else
                    return 1
                fi
            else
                print_status "ERROR" "🚫 Another QEMU instance is using this image"
                return 1
            fi
        fi
        return 1
    fi
    
    # Check for lock files
    local lock_file="${img_file}.lock"
    if [[ -f "$lock_file" ]]; then
        print_status "WARN" "🔒 Lock file found: $lock_file"
        
        # Check if lock file is stale (older than 5 minutes)
        if [[ $(find "$lock_file" -mmin +5 2>/dev/null) ]]; then
            print_status "WARN" "⏰ Lock file appears stale (older than 5 minutes)"
            read -p "$(print_status "INPUT" "🗑️  Remove stale lock file? (y/N): ")" remove_lock
            if [[ "$remove_lock" =~ ^[Yy]$ ]]; then
                rm -f "$lock_file"
                print_status "SUCCESS" "✅ Removed stale lock file"
                return 0
            else
                return 1
            fi
        fi
        return 1
    fi
    return 0
}

# Function to validate input
validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "❌ Must be a number"
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "❌ Must be a size with unit (e.g., 100G, 512M)"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 23 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "❌ Must be a valid port number (23-65535)"
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "❌ VM name can only contain letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "❌ Username must start with a letter or underscore, and contain only letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "vmid")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 100 ] || [ "$value" -gt 999999999 ]; then
                print_status "ERROR" "❌ VMID must be a number between 100 and 999999999"
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to check dependencies
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "qemu-img" "lsof")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check for cloud-init tools
    if ! command -v "cloud-localds" &> /dev/null; then
        if command -v "genisoimage" &> /dev/null; then
            print_status "INFO" "⚠️  Using genisoimage instead of cloud-localds"
        else
            missing_deps+=("cloud-image-utils")
        fi
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "ERROR" "🔧 Missing dependencies: ${missing_deps[*]}"
        print_status "INFO" "💡 On Ubuntu/Debian, try: sudo apt install qemu-system cloud-image-utils wget lsof genisoimage"
        exit 1
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "user-data" ]; then rm -f "user-data"; fi
    if [ -f "meta-data" ]; then rm -f "meta-data"; fi
}

# Function to get all VM configurations
get_vm_list() {
    find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

# Function to get Proxmox VMs
get_proxmox_vms() {
    if [[ -n "$PROXMOX_HOST" ]] && command -v pvesh &>/dev/null; then
        pvesh get /nodes/$PROXMOX_NODE/qemu --no-header 2>/dev/null | jq -r '.[].vmid' 2>/dev/null || echo ""
    fi
}

# Function to load VM configuration
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    
    if [[ -f "$config_file" ]]; then
        # Clear previous variables
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED USE_BRIDGE BRIDGE_IF
        unset PROXMOX_VMID PROXMOX_ENABLED
        
        source "$config_file"
        return 0
    else
        print_status "ERROR" "📂 Configuration for VM '$vm_name' not found"
        return 1
    fi
}

# Function to save VM configuration
save_vm_config() {
    local config_file="$VM_DIR/$VM_NAME.conf"
    
    cat > "$config_file" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
USE_BRIDGE="${USE_BRIDGE:-false}"
BRIDGE_IF="${BRIDGE_IF:-br0}"
PROXMOX_VMID="${PROXMOX_VMID:-}"
PROXMOX_ENABLED="${PROXMOX_ENABLED:-false}"
EOF
    
    print_status "SUCCESS" "💾 Configuration saved to $config_file"
}

# Function to download image with retry
download_image() {
    local url="$1"
    local output_file="$2"
    
    print_status "INFO" "🌐 Downloading image from $url..."
    
    # Try wget first
    if wget --progress=bar:force --no-check-certificate -q --show-progress "$url" -O "$output_file.tmp"; then
        mv "$output_file.tmp" "$output_file"
        return 0
    fi
    
    # Try curl if wget fails
    print_status "WARN" "⚠️  wget failed, trying curl..."
    if curl -L --progress-bar "$url" -o "$output_file.tmp"; then
        mv "$output_file.tmp" "$output_file"
        return 0
    fi
    
    # Try without progress if both fail
    print_status "WARN" "⚠️  curl failed, trying simple download..."
    if wget --no-check-certificate -q "$url" -O "$output_file.tmp"; then
        mv "$output_file.tmp" "$output_file"
        return 0
    fi
    
    return 1
}

# Function to create new VM
create_new_vm() {
    print_status "INFO" "🆕 Creating a new VM"
    
    # OS Selection
    print_status "INFO" "🌍 Select an OS to set up:"
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo "  $i) $os"
        os_options[$i]="$os"
        ((i++))
    done
    
    while true; do
        read -p "$(print_status "INPUT" "🎯 Enter your choice (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "❌ Invalid selection. Try again."
        fi
    done

    # Custom Inputs with validation
    while true; do
        read -p "$(print_status "INPUT" "🏷️  Enter VM name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            # Check if VM name already exists
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "⚠️  VM with name '$VM_NAME' already exists"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🏠 Enter hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "👤 Enter username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then
            break
        fi
    done

    while true; do
        read -s -p "$(print_status "INPUT" "🔑 Enter password (default: $DEFAULT_PASSWORD): ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then
            break
        else
            print_status "ERROR" "❌ Password cannot be empty"
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "💾 Disk size (default: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🧠 Memory in MB (default: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "⚡ Number of CPUs (default: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🔌 SSH Port (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            # Check if port is already in use
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "🚫 Port $SSH_PORT is already in use"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🖥️  Enable GUI mode? (y/n, default: n): ")" gui_input
        GUI_MODE=false
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            break
        else
            print_status "ERROR" "❌ Please answer y or n"
        fi
    done

    # Network options
    read -p "$(print_status "INPUT" "🌐 Use bridge networking? (requires sudo, y/N): ")" use_bridge
    USE_BRIDGE=false
    if [[ "$use_bridge" =~ ^[Yy]$ ]]; then
        USE_BRIDGE=true
        read -p "$(print_status "INPUT" "🔌 Bridge interface (default: br0): ")" BRIDGE_IF
        BRIDGE_IF="${BRIDGE_IF:-br0}"
    fi

    # Proxmox integration
    PROXMOX_ENABLED=false
    if [[ -n "$PROXMOX_HOST" ]]; then
        read -p "$(print_status "INPUT" "☁️  Create on Proxmox too? (y/N): ")" proxmox_create
        if [[ "$proxmox_create" =~ ^[Yy]$ ]]; then
            PROXMOX_ENABLED=true
            while true; do
                read -p "$(print_status "INPUT" "🔢 Proxmox VMID (100-999999999): ")" PROXMOX_VMID
                if validate_input "vmid" "$PROXMOX_VMID"; then
                    # Check if VMID already exists
                    if command -v pvesh &>/dev/null; then
                        if pvesh get /nodes/$PROXMOX_NODE/qemu/$PROXMOX_VMID/status --no-header 2>/dev/null; then
                            print_status "ERROR" "⚠️  VMID $PROXMOX_VMID already exists on Proxmox"
                        else
                            break
                        fi
                    else
                        break
                    fi
                fi
            done
        fi
    fi

    # Additional network options
    read -p "$(print_status "INPUT" "🌐 Additional port forwards (e.g., 8080:80, press Enter for none): ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    # Download and setup VM image
    setup_vm_image
    
    # Create on Proxmox if enabled
    if [[ "$PROXMOX_ENABLED" == true ]]; then
        create_proxmox_vm
    fi
    
    # Save configuration
    save_vm_config
}

# Function to setup VM image
setup_vm_image() {
    print_status "INFO" "📥 Downloading and preparing image..."
    
    # Create VM directory if it doesn't exist
    mkdir -p "$VM_DIR"
    
    # Check if image already exists
    if [[ -f "$IMG_FILE" ]]; then
        print_status "INFO" "✅ Image file already exists. Skipping download."
    else
        if ! download_image "$IMG_URL" "$IMG_FILE"; then
            print_status "ERROR" "❌ Failed to download image from $IMG_URL"
            # Try alternative URL for Debian daily builds
            if [[ "$CODENAME" == "trixie" ]]; then
                print_status "INFO" "🔄 Trying alternative Debian 13 URL..."
                ALT_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
                if download_image "$ALT_URL" "$IMG_FILE"; then
                    IMG_URL="$ALT_URL"
                else
                    exit 1
                fi
            else
                exit 1
            fi
        fi
    fi
    
    # Check image format
    if ! qemu-img info "$IMG_FILE" 2>/dev/null | grep -q "file format:"; then
        print_status "WARN" "⚠️  Image format detection failed, attempting conversion..."
        if qemu-img convert -f raw -O qcow2 "$IMG_FILE" "$IMG_FILE.converted" 2>/dev/null; then
            mv "$IMG_FILE.converted" "$IMG_FILE"
        fi
    fi
    
    # Resize the disk image if needed
    if ! qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null; then
        print_status "WARN" "⚠️  Failed to resize disk image. Creating new image with specified size..."
        # Create a new image with the specified size
        rm -f "$IMG_FILE"
        qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
    fi

    # cloud-init configuration
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    # Create seed image using available tool
    if command -v cloud-localds &> /dev/null; then
        cloud-localds "$SEED_FILE" user-data meta-data
    elif command -v genisoimage &> /dev/null; then
        genisoimage -output "$SEED_FILE" -volid cidata -joliet -rock user-data meta-data
    else
        print_status "ERROR" "❌ No tool available to create seed image"
        exit 1
    fi
    
    if [[ $? -eq 0 ]]; then
        print_status "SUCCESS" "🎉 VM '$VM_NAME' created successfully."
        print_status "INFO" "🔑 Login with: username=$USERNAME, password=$PASSWORD"
        print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
    else
        print_status "ERROR" "❌ Failed to create cloud-init seed image"
        exit 1
    fi
}

# Function to create VM on Proxmox
create_proxmox_vm() {
    print_status "INFO" "☁️  Creating VM on Proxmox..."
    
    if [[ -z "$PROXMOX_HOST" ]] 
