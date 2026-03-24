#!/bin/bash
################################################################################
# JACKASS - Jack of all trades Advanced Spec Sheet - Installer
# Version: 1.2
# Author/Owner: CYBERACQ
# GitHub: https://github.com/cyberacq/jackass
################################################################################
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# UTF-8 Braille spinner
SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_PID=""

# Installation paths
INSTALL_DIR="/usr/local/bin"
MANPAGE_DIR="/usr/share/man/man1"

# Debug mode
DEBUG=false

################################################################################
# Helper Functions
################################################################################
start_spinner() {
    local message="$1"
    (
        i=0
        while true; do
            printf "\r\033[K${YELLOW}${SPINNER_CHARS[$i]}${NC} $message"
            i=$(( (i + 1) % ${#SPINNER_CHARS[@]} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    local status="$1"
    local message="$2"
    
    if [ -n "$SPINNER_PID" ]; then
        kill $SPINNER_PID 2>/dev/null || true
        wait $SPINNER_PID 2>/dev/null || true
        SPINNER_PID=""
    fi
    
    if [ "$status" = "success" ]; then
        printf "\r\033[K${GREEN}✓${NC} $message\n"
    else
        printf "\r\033[K$message\n"
    fi
}

print_header() {
    local text="$1"
    local text_length=${#text}
    local border_length=$((text_length + 4))
    local border=$(printf '━%.0s' $(seq 1 $border_length))
    
    echo -e "${CYAN}${border}${NC}"
    echo -e "${CYAN}  $text${NC}"
    echo -e "${CYAN}${border}${NC}"
}

debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $*" >&2
    fi
}

################################################################################
# Dependency Check
################################################################################
check_installer_deps() {
    echo ""
    print_header "Dependency Check"
    echo ""
    
    local missing=()
    local required=("install" "gzip" "mandb")
    
    for dep in "${required[@]}"; do
        if ! command -v "$dep" > /dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing required tools:${NC} ${missing[*]}"
        echo ""
        read -p "Attempt to install missing dependencies? (Y/n): " install_choice
        
        if [ "$install_choice" != "n" ]; then
            if command -v apt > /dev/null 2>&1; then
                sudo apt install -y coreutils gzip man-db
            elif command -v dnf > /dev/null 2>&1; then
                sudo dnf install -y coreutils gzip man-db
            fi
        else
            echo "Cannot proceed without required tools."
            exit 1
        fi
    else
        echo -e "${GREEN}✓${NC} All installation dependencies satisfied"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

show_help() {
    cat << EOF
JACKASS - Jack of all trades Advanced Spec Sheet v1.2 - Installer

USAGE:
    sudo ./install-jackass.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version
    -c, --compatibility     Check installer dependencies
    --debug                 Enable debug mode
    
DESCRIPTION:
    Installs JACKASS to your system.

AFTER INSTALLATION:
    jackass                      Launch interactive viewer
    jackass --help               Show help
    jackass --compatibility      Check dependencies
    jackass --debug              Run with debug output
    man jackass                  Read manual

REQUIREMENTS:
    • Root privileges (run with sudo)
EOF
    exit 0
}

show_version() {
    echo "JACKASS Installer v1.2"
    exit 0
}

################################################################################
# Installation
################################################################################
install_jackass() {
    start_spinner "Creating jackass executable..."
    sleep 1.0
    
    # Create the complete JACKASS script
    cat > /tmp/jackass << 'JACKASS_EOF'
#!/bin/bash
################################################################################
# JACKASS - Jack of all trades Advanced Spec Sheet
# Version: 1.2
# Author/Owner: CYBERACQ
# GitHub: https://github.com/cyberacq/jackass
################################################################################

# Debug mode
DEBUG=false
DEBUG_LOG="/tmp/jackass-debug.log"

# Script metadata
SCRIPT_VERSION="1.2"
SCRIPT_NAME="jackass"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
BG_CYAN='\033[46m'

# Navigation
SELECTED=0
declare -a CATEGORIES=()
declare -A CATEGORY_DATA=()
declare -A CATEGORY_ISSUES=()
declare -a JACKASS_LINKS=()   # Populated by lookup_known_issues for clickable CVE/vuln URLs

# Required dependencies
REQUIRED_DEPS=("lscpu" "lspci" "lsblk" "ip")
OPTIONAL_DEPS=("dmidecode" "sensors" "nvidia-smi" "lsusb")

################################################################################
# Debug Functions
################################################################################
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG"
    fi
}

debug_init() {
    if [ "$DEBUG" = true ]; then
        echo "=== JACKASS Debug Session Started ===" > "$DEBUG_LOG"
        echo "Date: $(date)" >> "$DEBUG_LOG"
        echo "User: $(whoami)" >> "$DEBUG_LOG"
        echo "Terminal: $TERM" >> "$DEBUG_LOG"
        echo "" >> "$DEBUG_LOG"
    fi
}

debug_key() {
    if [ "$DEBUG" = true ]; then
        local key="$1"
        local hex=$(echo -n "$key" | xxd -p)
        debug_log "Key pressed - Raw: '$key' Hex: $hex Length: ${#key}"
    fi
}

################################################################################
# Helper Functions
################################################################################
print_title() {
    local width=76
    local title="JACKASS"
    local subtitle="Jack of all trades Advanced Spec Sheet v${SCRIPT_VERSION}"
    local title_padding=$(( (width - ${#title}) / 2 ))
    local subtitle_padding=$(( (width - ${#subtitle}) / 2 ))
    
    echo -e "${CYAN}${BOLD}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    printf "${CYAN}${BOLD}║${NC}%*s%s%*s${CYAN}${BOLD}║${NC}\n" $title_padding "" "$title" $((width - title_padding - ${#title})) ""
    printf "${CYAN}${BOLD}║${NC}%*s%s%*s${CYAN}${BOLD}║${NC}\n" $subtitle_padding "" "$subtitle" $((width - subtitle_padding - ${#subtitle})) ""
    echo -e "${CYAN}${BOLD}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
}

print_box() {
    local title="$1"
    local content="$2"
    local width=152
    
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $((width-2))))╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}${title}${NC}$(printf ' %.0s' $(seq 1 $((width - ${#title} - 3))))${BLUE}║${NC}"
    echo -e "${BLUE}╠$(printf '═%.0s' $(seq 1 $((width-2))))╣${NC}"
    
    while IFS= read -r line; do
        local clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local padding=$((width - ${#clean_line} - 3))
        [ $padding -lt 0 ] && padding=0
        echo -e "${BLUE}║${NC} ${line}$(printf ' %.0s' $(seq 1 $padding))${BLUE}║${NC}"
    done <<< "$content"
    
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $((width-2))))╝${NC}"
}

celsius_to_fahrenheit() {
    local celsius=$1
    echo "scale=1; ($celsius * 9 / 5) + 32" | bc 2>/dev/null || echo "N/A"
}

################################################################################
# Dependency Checking
################################################################################
check_dependencies() {
    echo ""
    print_title
    echo ""
    echo -e "${CYAN}${BOLD}Dependency Check${NC}"
    echo ""
    
    local missing_required=()
    local missing_optional=()
    
    echo "Checking required dependencies:"
    for dep in "${REQUIRED_DEPS[@]}"; do
        if command -v "$dep" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $dep"
        else
            echo -e "  ${RED}✗${NC} $dep (REQUIRED)"
            missing_required+=("$dep")
        fi
    done
    
    echo ""
    echo "Checking optional dependencies:"
    for dep in "${OPTIONAL_DEPS[@]}"; do
        if command -v "$dep" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $dep"
        else
            echo -e "  ${YELLOW}⚠${NC} $dep (optional)"
            missing_optional+=("$dep")
        fi
    done
    
    echo ""
    
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo -e "${RED}Missing required dependencies:${NC} ${missing_required[*]}"
        echo ""
        read -p "Would you like to attempt installation? (Y/n): " install_choice
        
        if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then
            install_dependencies "${missing_required[@]}"
        else
            echo "Cannot proceed without required dependencies."
            exit 1
        fi
    fi
    
    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing optional dependencies:${NC} ${missing_optional[*]}"
        echo "Some features will be limited."
        echo ""
        read -p "Would you like to install optional dependencies? (Y/n): " install_opt
        
        if [ "$install_opt" != "n" ] && [ "$install_opt" != "N" ]; then
            install_dependencies "${missing_optional[@]}"
        fi
    fi
    
    if [ ${#missing_required[@]} -eq 0 ] && [ ${#missing_optional[@]} -eq 0 ]; then
        echo -e "${GREEN}All dependencies satisfied!${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

install_dependencies() {
    local deps=("$@")
    
    if command -v apt > /dev/null 2>&1; then
        sudo apt update
        sudo apt install -y "${deps[@]}"
    elif command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y "${deps[@]}"
    elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y "${deps[@]}"
    elif command -v pacman > /dev/null 2>&1; then
        sudo pacman -S --noconfirm "${deps[@]}"
    else
        echo "Cannot detect package manager. Please install manually: ${deps[*]}"
    fi
}

################################################################################
# Hardware Information Gathering
################################################################################
get_cpu_info() {
    local info=""

    if command -v lscpu > /dev/null 2>&1; then
        local model arch vendor cores sockets threads_per_core total_threads
        local min_freq max_freq cur_freq cache_l1d cache_l1i cache_l2 cache_l3
        local numa_nodes virt flags microcode

        model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
        arch=$(lscpu | grep "^Architecture" | awk '{print $2}')
        vendor=$(lscpu | grep "Vendor ID" | cut -d':' -f2 | xargs)
        sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}')
        cores=$(lscpu | grep "^Core(s) per socket:" | awk '{print $NF}')
        total_threads=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
        threads_per_core=$(lscpu | grep "Thread(s) per core" | awk '{print $NF}')
        numa_nodes=$(lscpu | grep "^NUMA node(s):" | awk '{print $NF}')
        virt=$(lscpu | grep "Virtualization" | cut -d':' -f2 | xargs)

        # Frequencies
        max_freq=$(lscpu | grep "CPU max MHz" | awk '{printf "%.0f", $NF}')
        min_freq=$(lscpu | grep "CPU min MHz" | awk '{printf "%.0f", $NF}')
        cur_freq=$(lscpu | grep "^CPU MHz"    | awk '{printf "%.0f", $NF}')

        # Cache
        cache_l1d=$(lscpu | grep "L1d cache" | cut -d':' -f2 | xargs)
        cache_l1i=$(lscpu | grep "L1i cache" | cut -d':' -f2 | xargs)
        cache_l2=$(lscpu  | grep "L2 cache"  | cut -d':' -f2 | xargs)
        cache_l3=$(lscpu  | grep "L3 cache"  | cut -d':' -f2 | xargs)

        # Microcode
        microcode=$(grep -m1 "microcode" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | xargs)

        info+="${BOLD}Model:${NC} ${model}\n"
        info+="${BOLD}Vendor:${NC} ${vendor}\n"
        info+="${BOLD}Architecture:${NC} ${arch}\n"
        [ -n "$virt" ] && info+="${BOLD}Virtualization:${NC} ${virt}\n"
        info+="\n"

        info+="${BOLD}── Topology ──${NC}\n"
        info+="  ${BOLD}Sockets:${NC} ${sockets}\n"
        info+="  ${BOLD}Cores per socket:${NC} ${cores}\n"
        info+="  ${BOLD}Threads per core:${NC} ${threads_per_core}\n"
        info+="  ${BOLD}Total logical CPUs:${NC} ${total_threads}\n"
        [ -n "$numa_nodes" ] && info+="  ${BOLD}NUMA nodes:${NC} ${numa_nodes}\n"
        info+="\n"

        info+="${BOLD}── Frequencies ──${NC}\n"
        [ -n "$cur_freq" ] && info+="  ${BOLD}Current:${NC} ${cur_freq} MHz\n"
        [ -n "$max_freq" ] && info+="  ${BOLD}Max (boost):${NC} ${max_freq} MHz\n"
        [ -n "$min_freq" ] && info+="  ${BOLD}Min:${NC} ${min_freq} MHz\n"
        info+="\n"

        info+="${BOLD}── Cache ──${NC}\n"
        [ -n "$cache_l1d" ] && info+="  ${BOLD}L1d:${NC} ${cache_l1d}\n"
        [ -n "$cache_l1i" ] && info+="  ${BOLD}L1i:${NC} ${cache_l1i}\n"
        [ -n "$cache_l2"  ] && info+="  ${BOLD}L2:${NC}  ${cache_l2}\n"
        [ -n "$cache_l3"  ] && info+="  ${BOLD}L3:${NC}  ${cache_l3}\n"
        info+="\n"

        [ -n "$microcode" ] && info+="${BOLD}Microcode:${NC} ${microcode}\n"

        # Temperature
        if command -v sensors > /dev/null 2>&1; then
            local temp
            temp=$(sensors 2>/dev/null | grep -i "core 0" | grep -o '[+-][0-9][0-9]*\.[0-9]*' | head -1 | tr -d '+')
            if [ -n "$temp" ]; then
                local temp_f=$(celsius_to_fahrenheit "$temp")
                info+="${BOLD}Temperature (Core 0):${NC} ${temp}°C (${temp_f}°F)\n"
            fi
        elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            local raw_t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
            if [ -n "$raw_t" ]; then
                local celsius=$(echo "scale=1; $raw_t/1000" | bc 2>/dev/null || echo "$((raw_t/1000))")
                info+="${BOLD}Temperature:${NC} ${celsius}°C ($(celsius_to_fahrenheit "$celsius")°F)\n"
            fi
        fi

        # PCIe lanes note — not directly readable from userspace without root+dmidecode
        info+="\n${BOLD}── PCIe / Bus ──${NC}\n"
        if command -v lspci > /dev/null 2>&1; then
            # Show CPU-connected PCIe root ports (host bridges)
            local pcie_roots
            pcie_roots=$(lspci 2>/dev/null | grep -i "pci bridge\|host bridge\|root port" | head -10)
            if [ -n "$pcie_roots" ]; then
                info+="  ${BOLD}PCIe Root Ports / Host Bridges:${NC}\n"
                while IFS= read -r pline; do
                    info+="    ${pline}\n"
                done <<< "$pcie_roots"
            fi
        fi
        info+="  ${CYAN}Note: Total CPU PCIe lane count requires 'dmidecode' (root) or${NC}\n"
        info+="  ${CYAN}vendor-specific tools (e.g. turbostat, cpuid). lscpu does not expose it.${NC}\n"

        # CPU flags (highlight useful ones)
        info+="\n${BOLD}── Notable CPU Flags ──${NC}\n"
        local all_flags
        all_flags=$(grep -m1 "^flags" /proc/cpuinfo 2>/dev/null | cut -d':' -f2)
        local notable=("avx" "avx2" "avx512f" "aes" "sse4_2" "vmx" "svm" "rdrand" "sha_ni" "bmi2" "f16c" "lm")
        local found_flags=()
        for f in "${notable[@]}"; do
            echo "$all_flags" | grep -qw "$f" && found_flags+=("$f")
        done
        if [ ${#found_flags[@]} -gt 0 ]; then
            info+="  ${found_flags[*]}\n"
        else
            info+="  (could not read /proc/cpuinfo flags)\n"
        fi
    fi

    echo -e "$info"
}

get_memory_info() {
    local info=""

    # ── System memory summary from /proc/meminfo ──
    if [ -f /proc/meminfo ]; then
        local total available used swap_total swap_used
        total=$(grep MemTotal    /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        available=$(grep MemAvailable /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        used=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.2f GB", (t-a)/1024/1024}' /proc/meminfo)
        swap_total=$(grep SwapTotal /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        swap_used=$(awk '/SwapTotal/{t=$2} /SwapFree/{f=$2} END{printf "%.2f GB", (t-f)/1024/1024}' /proc/meminfo)

        info+="${BOLD}── Usage ──${NC}\n"
        info+="  ${BOLD}Total RAM:${NC}   ${total}\n"
        info+="  ${BOLD}Used:${NC}        ${used}\n"
        info+="  ${BOLD}Available:${NC}   ${available}\n"
        info+="  ${BOLD}Swap Total:${NC}  ${swap_total}\n"
        info+="  ${BOLD}Swap Used:${NC}   ${swap_used}\n"
        info+="\n"
    fi

    # ── Per-DIMM hardware details via dmidecode (requires root) ──
    if command -v dmidecode > /dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
        info+="${BOLD}── Installed DIMMs (dmidecode) ──${NC}\n"

        local slot_output
        slot_output=$(dmidecode -t memory 2>/dev/null)

        local slot_num=0
        local in_device=false
        local locator size type speed mfr part serial form configured_speed voltage

        while IFS= read -r dline; do
            if echo "$dline" | grep -q "^Memory Device$"; then
                # Flush previous slot if it had a real size
                if [ "$in_device" = true ] && [ -n "$size" ] && [ "$size" != "No Module Installed" ] && [ "$size" != "Unknown" ]; then
                    info+="  ${BOLD}Slot ${slot_num}:${NC} ${locator}\n"
                    info+="    Size:             ${size}\n"
                    info+="    Type:             ${type}\n"
                    info+="    Form Factor:      ${form}\n"
                    info+="    Speed:            ${speed}\n"
                    info+="    Configured Speed: ${configured_speed}\n"
                    info+="    Manufacturer:     ${mfr}\n"
                    info+="    Part Number:      ${part}\n"
                    info+="    Serial Number:    ${serial}\n"
                    [ -n "$voltage" ] && info+="    Voltage:          ${voltage}\n"
                    info+="\n"
                fi
                slot_num=$((slot_num + 1))
                in_device=true
                locator="" size="" type="" speed="" mfr="" part="" serial="" form="" configured_speed="" voltage=""
                continue
            fi
            if [ "$in_device" = true ]; then
                local key val
                key=$(echo "$dline" | sed 's/^\s*//' | cut -d':' -f1 | xargs)
                val=$(echo "$dline" | cut -d':' -f2- | xargs)
                case "$key" in
                    "Locator")              [ -z "$locator" ] && locator="$val" ;;
                    "Size")                 size="$val" ;;
                    "Type")                 type="$val" ;;
                    "Form Factor")          form="$val" ;;
                    "Speed")                speed="$val" ;;
                    "Configured Memory Speed"|"Configured Clock Speed") configured_speed="$val" ;;
                    "Manufacturer")         mfr="$val" ;;
                    "Part Number")          part="$val" ;;
                    "Serial Number")        serial="$val" ;;
                    "Voltage")              voltage="$val" ;;
                esac
            fi
        done <<< "$slot_output"

        # Flush the last device
        if [ "$in_device" = true ] && [ -n "$size" ] && [ "$size" != "No Module Installed" ] && [ "$size" != "Unknown" ]; then
            info+="  ${BOLD}Slot ${slot_num}:${NC} ${locator}\n"
            info+="    Size:             ${size}\n"
            info+="    Type:             ${type}\n"
            info+="    Form Factor:      ${form}\n"
            info+="    Speed:            ${speed}\n"
            info+="    Configured Speed: ${configured_speed}\n"
            info+="    Manufacturer:     ${mfr}\n"
            info+="    Part Number:      ${part}\n"
            info+="    Serial Number:    ${serial}\n"
            [ -n "$voltage" ] && info+="    Voltage:          ${voltage}\n"
            info+="\n"
        fi

        # Also show total/max capacity from array
        local max_cap num_slots
        max_cap=$(dmidecode -t memory 2>/dev/null | grep "Maximum Capacity" | head -1 | cut -d':' -f2 | xargs)
        num_slots=$(dmidecode -t memory 2>/dev/null | grep "Number Of Devices" | head -1 | cut -d':' -f2 | xargs)
        [ -n "$max_cap"   ] && info+="  ${BOLD}Max Board Capacity:${NC} ${max_cap}\n"
        [ -n "$num_slots" ] && info+="  ${BOLD}Total DIMM Slots:${NC}   ${num_slots}\n"

    elif command -v dmidecode > /dev/null 2>&1 && [ "$EUID" -ne 0 ]; then
        info+="${YELLOW}Note: Run as root (sudo jackass) to see DIMM manufacturer, part/serial numbers and slot details.${NC}\n"
        # Still show speed from dmidecode if we can get it without root — we can't, but show the note
        info+="${BOLD}Tip:${NC} sudo dmidecode -t memory\n"
    else
        info+="${YELLOW}dmidecode not installed — install it for full DIMM hardware details.${NC}\n"
    fi

    echo -e "$info"
}

get_gpu_info() {
    local info=""
    
    if command -v lspci > /dev/null 2>&1; then
        local gpus=$(lspci | grep -i 'vga\|3d\|display')
        
        if [ -n "$gpus" ]; then
            while IFS= read -r gpu; do
                local gpu_name=$(echo "$gpu" | cut -d':' -f3 | xargs)
                info+="${BOLD}GPU:${NC} $gpu_name\n"
            done <<< "$gpus"
        fi
    fi
    
    if command -v nvidia-smi > /dev/null 2>&1; then
        local nv_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)
        if [ -n "$nv_temp" ]; then
            local temp_f=$(celsius_to_fahrenheit "$nv_temp")
            info+="${BOLD}Temperature:${NC} ${nv_temp}°C (${temp_f}°F)\n"
        fi
    fi
    
    [ -z "$info" ] && info="No GPU information available"
    echo -e "$info"
}

get_temps_fans() {
    local info=""
    local found=false

    # --- lm-sensors ---
    if command -v sensors > /dev/null 2>&1; then
        local current_chip=""
        while IFS= read -r line; do
            # Chip/adapter header lines (no colon value pair)
            if echo "$line" | grep -qE '^[A-Za-z]' && ! echo "$line" | grep -qE ':'; then
                current_chip="$line"
                continue
            fi
            # Temperature lines  e.g.  "Core 0:        +42.0°C"
            if echo "$line" | grep -q "°C"; then
                local sensor temp
                sensor=$(echo "$line" | cut -d':' -f1 | xargs)
                # Extract first numeric value after + or - before °
                temp=$(echo "$line" | grep -o '[+-][0-9][0-9]*\.[0-9]*' | head -1 | tr -d '+')
                if [ -n "$temp" ]; then
                    local temp_f=$(celsius_to_fahrenheit "$temp")
                    [ -n "$current_chip" ] && info+="${BOLD}[${current_chip}]${NC}\n" && current_chip=""
                    info+="  ${BOLD}${sensor}:${NC} ${temp}°C (${temp_f}°F)\n"
                    found=true
                fi
            fi
            # Fan lines  e.g.  "fan1:        1200 RPM"
            if echo "$line" | grep -qiE 'fan[0-9]*\s*:'; then
                local fan_name fan_val
                fan_name=$(echo "$line" | cut -d':' -f1 | xargs)
                fan_val=$(echo "$line" | cut -d':' -f2 | xargs)
                [ -n "$current_chip" ] && info+="${BOLD}[${current_chip}]${NC}\n" && current_chip=""
                info+="  ${BOLD}${fan_name}:${NC} ${fan_val}\n"
                found=true
            fi
        done < <(sensors 2>/dev/null)
    fi

    # --- /sys/class/thermal fallback (works without lm-sensors) ---
    if [ "$found" = false ] && [ -d /sys/class/thermal ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            local zone_temp zone_type
            zone_temp=$(cat "${zone}/temp" 2>/dev/null)
            zone_type=$(cat "${zone}/type" 2>/dev/null)
            if [ -n "$zone_temp" ]; then
                local celsius=$(echo "scale=1; $zone_temp / 1000" | bc 2>/dev/null || echo "$((zone_temp/1000))")
                local fahr=$(celsius_to_fahrenheit "$celsius")
                info+="  ${BOLD}${zone_type:-$(basename $zone)}:${NC} ${celsius}°C (${fahr}°F)\n"
                found=true
            fi
        done
    fi

    # --- hwmon fan fallback ---
    if [ -d /sys/class/hwmon ]; then
        for hwmon in /sys/class/hwmon/hwmon*; do
            for fan_input in "${hwmon}"/fan*_input; do
                [ -f "$fan_input" ] || continue
                local rpm label
                rpm=$(cat "$fan_input" 2>/dev/null)
                local label_file="${fan_input/_input/_label}"
                label=$(cat "$label_file" 2>/dev/null || basename "$fan_input" _input)
                [ -n "$rpm" ] && info+="  ${BOLD}${label}:${NC} ${rpm} RPM\n" && found=true
            done
        done
    fi

    # --- NVIDIA GPU temp (already shown in GPU section, but useful here too) ---
    if command -v nvidia-smi > /dev/null 2>&1; then
        local nv_temp
        nv_temp=$(nvidia-smi --query-gpu=name,temperature.gpu,fan.speed \
                    --format=csv,noheader 2>/dev/null)
        if [ -n "$nv_temp" ]; then
            while IFS= read -r nv_line; do
                local gpu_name gpu_t gpu_fan
                gpu_name=$(echo "$nv_line" | cut -d',' -f1 | xargs)
                gpu_t=$(echo "$nv_line" | cut -d',' -f2 | xargs | tr -dc '0-9.')
                gpu_fan=$(echo "$nv_line" | cut -d',' -f3 | xargs)
                [ -n "$gpu_t" ] && info+="  ${BOLD}NVIDIA ${gpu_name} Temp:${NC} ${gpu_t}°C ($(celsius_to_fahrenheit "$gpu_t")°F)\n" && found=true
                [ -n "$gpu_fan" ] && info+="  ${BOLD}NVIDIA ${gpu_name} Fan:${NC} ${gpu_fan}\n"
            done <<< "$nv_temp"
        fi
    fi

    if [ "$found" = false ]; then
        info="No temperature/fan data available.\n"
        info+="Tip: install lm-sensors and run 'sudo sensors-detect' to enable sensor support.\n"
    fi

    echo -e "$info"
}

get_storage_info() {
    local info=""

    # Header line
    info+="${BOLD}$(printf '%-20s %-10s %-8s %-12s %-20s %s' 'NAME' 'SIZE' 'TYPE' 'TRAN' 'MOUNTPOINT' 'MODEL')${NC}\n"
    info+="$(printf '%.0s─' {1..90})\n"

    # lsblk: include transport (tran) so NVMe/SATA/USB are visible; show all disks + partitions
    while IFS= read -r line; do
        info+="${line}\n"
    done < <(lsblk -o NAME,SIZE,TYPE,TRAN,MOUNTPOINT,MODEL 2>/dev/null \
        | grep -v "^loop" \
        | awk 'NR>1')   # skip lsblk's own header – we printed our own

    # If lsblk gave nothing useful, fall back
    if [ -z "$(lsblk -d -o NAME 2>/dev/null | grep -v 'loop\|NAME')" ]; then
        info+="No block devices detected\n"
        echo -e "$info"
        return
    fi

    info+="\n"

    # Per-disk detail: model, serial, rotation, size (needs root for some)
    info+="${BOLD}Disk Details:${NC}\n"
    while IFS= read -r disk; do
        local model size rota serial transport
        model=$(cat /sys/block/${disk}/device/model 2>/dev/null | xargs)
        size=$(lsblk -d -n -o SIZE /dev/${disk} 2>/dev/null | xargs)
        rota=$(cat /sys/block/${disk}/queue/rotational 2>/dev/null)
        serial=$(cat /sys/block/${disk}/device/serial 2>/dev/null | xargs 2>/dev/null || \
                 udevadm info --query=property --name=/dev/${disk} 2>/dev/null | grep ID_SERIAL= | cut -d= -f2)
        transport=$(cat /sys/block/${disk}/queue/zoned 2>/dev/null; \
                    udevadm info --query=property --name=/dev/${disk} 2>/dev/null | grep ID_BUS= | cut -d= -f2)

        # Determine drive type
        local dtype="Unknown"
        if [[ "$disk" == nvme* ]]; then
            dtype="NVMe/M.2"
        elif [ "$rota" = "0" ]; then
            dtype="SSD"
        elif [ "$rota" = "1" ]; then
            dtype="HDD"
        fi

        [ -z "$model" ] && model="(no model info)"
        [ -z "$serial" ] && serial="N/A"

        info+="  ${BOLD}/dev/${disk}${NC} — ${dtype}, ${size}"
        [ -n "$model" ] && info+=", Model: ${model}"
        info+="\n"
        info+="    Serial: ${serial}\n"
    done < <(lsblk -d -n -o NAME 2>/dev/null | grep -v '^loop')

    echo -e "$info"
}

get_network_info() {
    local info=""

    info+="${BOLD}INTERFACE        STATE        ADDRESSES${NC}\n"
    info+="────────────────────────────────────────────────────────────────────────────────\n"

    while IFS= read -r line; do
        local iface state addrs
        iface=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        addrs=$(echo "$line" | awk '{$1=$2=""; print $0}' | xargs)

        # Colour-code state
        local state_colored
        case "$state" in
            UP)       state_colored="${GREEN}UP${NC}" ;;
            DOWN)     state_colored="${RED}DOWN${NC}" ;;
            UNKNOWN)  state_colored="${YELLOW}UNKNOWN${NC}" ;;
            *)        state_colored="$state" ;;
        esac

        info+="${BOLD}$(printf '%-16s' "$iface")${NC} ${state_colored}\n"

        # Each address on its own indented line
        for addr in $addrs; do
            info+="    ${addr}\n"
        done

        # Extra info: MAC, speed, MTU
        local mac speed mtu link_type
        mac=$(ip link show "$iface" 2>/dev/null | awk '/link\// {print $2}')
        mtu=$(ip link show "$iface" 2>/dev/null | grep -o 'mtu [0-9]*' | awk '{print $2}')
        speed=$(cat /sys/class/net/${iface}/speed 2>/dev/null)
        link_type=$(ip link show "$iface" 2>/dev/null | awk '/link\// {print $1}' | tr -d ':')

        [ -n "$mac" ]   && info+="    MAC: ${mac}"
        [ -n "$mtu" ]   && info+="  MTU: ${mtu}"
        [ -n "$speed" ] && [ "$speed" != "-1" ] && info+="  Speed: ${speed} Mbps"
        [ -n "$mac" ] || [ -n "$mtu" ] && info+="\n"
        info+="\n"
    done < <(ip -br addr 2>/dev/null)

    [ -z "$(ip -br addr 2>/dev/null)" ] && info+="No network interfaces found\n"

    echo -e "$info"
}

get_os_info() {
    local info=""

    # Distro identity — prefer os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        info+="${BOLD}Distribution:${NC} ${PRETTY_NAME:-${NAME}}\n"
        [ -n "$VERSION" ]        && info+="${BOLD}Version:${NC} ${VERSION}\n"
        [ -n "$VERSION_CODENAME" ] && info+="${BOLD}Codename:${NC} ${VERSION_CODENAME}\n"
        [ -n "$VERSION_ID" ]     && info+="${BOLD}Version ID:${NC} ${VERSION_ID}\n"
        [ -n "$ID_LIKE" ]        && info+="${BOLD}Base:${NC} ${ID_LIKE}\n"
        [ -n "$HOME_URL" ]       && info+="${BOLD}Homepage:${NC} ${HOME_URL}\n"
        [ -n "$SUPPORT_URL" ]    && info+="${BOLD}Support:${NC} ${SUPPORT_URL}\n"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        info+="${BOLD}Distribution:${NC} ${DISTRIB_DESCRIPTION:-${DISTRIB_ID}}\n"
        [ -n "$DISTRIB_RELEASE" ] && info+="${BOLD}Release:${NC} ${DISTRIB_RELEASE}\n"
        [ -n "$DISTRIB_CODENAME" ] && info+="${BOLD}Codename:${NC} ${DISTRIB_CODENAME}\n"
    else
        info+="${BOLD}Distribution:${NC} Unknown (no os-release found)\n"
    fi

    # Variant detection
    local variant=""
    # Desktop environment
    [ -n "$XDG_CURRENT_DESKTOP" ] && variant="$XDG_CURRENT_DESKTOP"
    [ -z "$variant" ] && [ -n "$DESKTOP_SESSION" ] && variant="$DESKTOP_SESSION"
    [ -z "$variant" ] && pgrep -x gnome-shell  >/dev/null 2>&1 && variant="GNOME"
    [ -z "$variant" ] && pgrep -x plasmashell  >/dev/null 2>&1 && variant="KDE Plasma"
    [ -z "$variant" ] && pgrep -x xfce4-session>/dev/null 2>&1 && variant="Xfce"
    [ -z "$variant" ] && pgrep -x lxsession   >/dev/null 2>&1 && variant="LXDE"
    [ -z "$variant" ] && pgrep -x mate-session >/dev/null 2>&1 && variant="MATE"
    [ -n "$variant" ] && info+="${BOLD}Desktop:${NC} ${variant}\n"

    # WSL detection
    if grep -qi microsoft /proc/version 2>/dev/null; then
        info+="${BOLD}Environment:${NC} Windows Subsystem for Linux (WSL)\n"
    elif systemd-detect-virt --quiet --container 2>/dev/null; then
        info+="${BOLD}Environment:${NC} Container ($(systemd-detect-virt --container 2>/dev/null))\n"
    elif systemd-detect-virt --quiet --vm 2>/dev/null; then
        info+="${BOLD}Environment:${NC} Virtual Machine ($(systemd-detect-virt --vm 2>/dev/null))\n"
    fi

    info+="\n"

    # Kernel & hardware
    info+="${BOLD}Kernel:${NC} $(uname -r)\n"
    info+="${BOLD}Architecture:${NC} $(uname -m)\n"
    info+="${BOLD}Hostname:${NC} $(hostname)\n"

    # Uptime
    if [ -f /proc/uptime ]; then
        local seconds=$(awk '{print int($1)}' /proc/uptime)
        local days=$((seconds/86400))
        local hours=$(( (seconds%86400)/3600 ))
        local mins=$(( (seconds%3600)/60 ))
        info+="${BOLD}Uptime:${NC} ${days}d ${hours}h ${mins}m\n"
    fi

    # Init system
    local init_sys="Unknown"
    if [ -d /run/systemd/system ]; then
        init_sys="systemd"
    elif [ -f /sbin/openrc ]; then
        init_sys="OpenRC"
    elif [ -f /sbin/runit ]; then
        init_sys="runit"
    fi
    info+="${BOLD}Init System:${NC} ${init_sys}\n"

    # Package count (best-effort)
    local pkgs=""
    if command -v dpkg > /dev/null 2>&1; then
        pkgs="$(dpkg -l 2>/dev/null | grep -c '^ii') (dpkg)"
    elif command -v rpm > /dev/null 2>&1; then
        pkgs="$(rpm -qa 2>/dev/null | wc -l) (rpm)"
    elif command -v pacman > /dev/null 2>&1; then
        pkgs="$(pacman -Q 2>/dev/null | wc -l) (pacman)"
    fi
    [ -n "$pkgs" ] && info+="${BOLD}Packages:${NC} ${pkgs}\n"

    # Shell
    info+="${BOLD}Shell:${NC} ${SHELL} ($(${SHELL} --version 2>&1 | head -1))\n"

    echo -e "$info"
}

################################################################################
# Desktop / browser detection for clickable links
################################################################################
is_desktop_linux() {
    # Returns 0 (true) if we are running inside a graphical desktop session
    # that has xdg-open available (GNOME, KDE, Xfce, etc.)
    if ! command -v xdg-open > /dev/null 2>&1; then
        return 1
    fi
    # Check for a display server (X11 or Wayland)
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || \
       [ -n "$XDG_CURRENT_DESKTOP" ] || [ -n "$DESKTOP_SESSION" ]; then
        return 0
    fi
    return 1
}

open_url() {
    local url="$1"
    if is_desktop_linux; then
        xdg-open "$url" > /dev/null 2>&1 &
        echo -e "${GREEN}Opening in browser:${NC} $url"
    else
        echo -e "${YELLOW}No desktop browser detected.${NC}"
        echo -e "Visit manually: ${CYAN}${url}${NC}"
    fi
}


lookup_known_issues() {
    local category="$1"
    local hw_string="$2"
    local issues=""

    # Check for internet connectivity first
    if ! (command -v curl > /dev/null 2>&1 || command -v wget > /dev/null 2>&1); then
        echo "curl/wget not available — cannot check online databases."
        return
    fi

    local can_reach=false
    if command -v curl > /dev/null 2>&1; then
        curl -sf --max-time 3 "https://www.google.com" > /dev/null 2>&1 && can_reach=true
    elif command -v wget > /dev/null 2>&1; then
        wget -q --timeout=3 -O /dev/null "https://www.google.com" > /dev/null 2>&1 && can_reach=true
    fi

    if [ "$can_reach" = false ]; then
        echo "No internet access — online lookup skipped."
        return
    fi

    # ── Query Linux kernel CVE database ──
    # https://www.cve.org / https://access.redhat.com/security (JSON APIs)
    # We use the NIST NVD CPE search as a lightweight JSON API
    local search_term
    search_term=$(echo "$hw_string" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | awk '{print $1"_"$2}')

    issues+="${BOLD}── Kernel Microcode / CVE Check ──${NC}\n"

    # Check running kernel against known CVE list via Ubuntu/Debian security tracker (text)
    local kernel_ver
    kernel_ver=$(uname -r)

    if command -v curl > /dev/null 2>&1; then
        # Check if current CPU microcode is up to date via Intel/AMD errata page
        # Use a simple NVD keyword search (public, no auth needed)
        local nvd_url="https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=$(echo "$hw_string" | sed 's/ /+/g')&resultsPerPage=3"
        local nvd_result
        nvd_result=$(curl -sf --max-time 8 "$nvd_url" 2>/dev/null)

        if [ -n "$nvd_result" ]; then
            local total_results
            total_results=$(echo "$nvd_result" | grep -o '"totalResults":[0-9]*' | cut -d':' -f2)
            issues+="  NVD CVE search for \"${hw_string}\": ${total_results:-0} result(s) found\n"

            # Extract up to 5 CVE IDs and store links for interactive opening
            local cve_ids
            cve_ids=$(echo "$nvd_result" | grep -o '"CVE-[0-9-]*"' | tr -d '"' | head -5)
            if [ -n "$cve_ids" ]; then
                issues+="  Recent CVEs:\n"
                local idx=1
                while IFS= read -r cve; do
                    local cve_url="https://nvd.nist.gov/vuln/detail/${cve}"
                    JACKASS_LINKS+=("$cve_url")
                    local link_num=${#JACKASS_LINKS[@]}
                    issues+="    ${YELLOW}${cve}${NC} [${CYAN}link ${link_num}${NC}] ${GRAY}${cve_url}${NC}\n"
                    idx=$((idx+1))
                done <<< "$cve_ids"
                if is_desktop_linux; then
                    issues+="  ${DIM}(Press O in detail view to open a CVE link in browser)${NC}\n"
                fi
            else
                issues+="  ${GREEN}No recent CVEs found in NVD for this hardware string.${NC}\n"
            fi
        else
            issues+="  ${YELLOW}NVD API did not respond — try again later.${NC}\n"
        fi
    fi

    # ── Spectre/Meltdown / CPU vulnerability files (kernel exposes these) ──
    if [ "$category" = "CPU" ] && [ -d /sys/devices/system/cpu/vulnerabilities ]; then
        issues+="\n${BOLD}── CPU Vulnerability Status (kernel) ──${NC}\n"
        for vfile in /sys/devices/system/cpu/vulnerabilities/*; do
            local vname vstatus
            vname=$(basename "$vfile")
            vstatus=$(cat "$vfile" 2>/dev/null)
            case "$vstatus" in
                *"Not affected"*)   issues+="  ${GREEN}✓${NC} ${vname}: ${vstatus}\n" ;;
                *"Mitigation"*)     issues+="  ${YELLOW}⚠${NC} ${vname}: ${vstatus}\n" ;;
                *"Vulnerable"*)     issues+="  ${RED}✗${NC} ${vname}: ${vstatus}\n" ;;
                *)                  issues+="    ${vname}: ${vstatus}\n" ;;
            esac
        done
    fi

    # ── Microcode currency check ──
    if [ "$category" = "CPU" ]; then
        local microcode_ver
        microcode_ver=$(grep -m1 "microcode" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | xargs)
        [ -n "$microcode_ver" ] && issues+="\n${BOLD}Loaded microcode revision:${NC} ${microcode_ver}\n"
        issues+="${CYAN}Tip: Compare with latest from intel-microcode / amd64-microcode package.${NC}\n"
    fi

    # ── Storage SMART status ──
    if [ "$category" = "Storage" ]; then
        issues+="\n${BOLD}── SMART Health Summary ──${NC}\n"
        if command -v smartctl > /dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
            while IFS= read -r disk; do
                local smart_status
                smart_status=$(smartctl -H /dev/"$disk" 2>/dev/null | grep "SMART overall-health" | cut -d':' -f2 | xargs)
                if [ -n "$smart_status" ]; then
                    case "$smart_status" in
                        *PASSED*) issues+="  ${GREEN}✓${NC} /dev/${disk}: ${smart_status}\n" ;;
                        *FAILED*) issues+="  ${RED}✗${NC} /dev/${disk}: ${smart_status}\n" ;;
                        *)        issues+="    /dev/${disk}: ${smart_status}\n" ;;
                    esac
                fi
            done < <(lsblk -d -n -o NAME 2>/dev/null | grep -v '^loop')
        elif command -v smartctl > /dev/null 2>&1; then
            issues+="  ${YELLOW}Run as root (sudo jackass) for SMART health data.${NC}\n"
        else
            issues+="  smartmontools not installed. Install with: sudo apt install smartmontools\n"
        fi
    fi

    [ -z "$issues" ] && issues="No issues data available for this category.\n"
    echo -e "$issues"
}


init_categories() {
    debug_log "Initializing categories..."
    JACKASS_LINKS=()   # reset global link list
    
    CATEGORIES=("CPU" "Memory" "GPU" "Storage" "Network" "OS Info" "PCI Devices" "USB Devices" "Temperatures & Fans")
    
    debug_log "Gathering CPU info..."
    CATEGORY_DATA["CPU"]=$(get_cpu_info)
    
    debug_log "Gathering Memory info..."
    CATEGORY_DATA["Memory"]=$(get_memory_info)
    
    debug_log "Gathering GPU info..."
    CATEGORY_DATA["GPU"]=$(get_gpu_info)
    
    debug_log "Gathering Storage info..."
    CATEGORY_DATA["Storage"]=$(get_storage_info)
    
    debug_log "Gathering Network info..."
    CATEGORY_DATA["Network"]=$(get_network_info)
    
    debug_log "Gathering OS info..."
    CATEGORY_DATA["OS Info"]=$(get_os_info)
    
    debug_log "Gathering PCI info..."
    CATEGORY_DATA["PCI Devices"]=$(lspci 2>/dev/null | head -30)
    
    debug_log "Gathering USB info..."
    CATEGORY_DATA["USB Devices"]=$(lsusb 2>/dev/null || echo "lsusb not available")
    
    debug_log "Gathering Temperature info..."
    CATEGORY_DATA["Temperatures & Fans"]=$(get_temps_fans)
    
    debug_log "Gathering known issues..."
    local cpu_model=$(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs | cut -c1-60)
    local gpu_model=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | cut -d':' -f3 | xargs | cut -c1-50)

    CATEGORY_ISSUES["CPU"]=$(lookup_known_issues "CPU" "${cpu_model:-Linux CPU}")
    CATEGORY_ISSUES["GPU"]=$(lookup_known_issues "GPU" "${gpu_model:-Linux GPU}")
    CATEGORY_ISSUES["Storage"]=$(lookup_known_issues "Storage" "storage disk Linux")
    CATEGORY_ISSUES["Memory"]=$(lookup_known_issues "Memory" "memory DDR Linux")
    CATEGORY_ISSUES["Network"]=$(lookup_known_issues "Network" "network driver Linux kernel")
    CATEGORY_ISSUES["OS Info"]=$(lookup_known_issues "OS Info" "$(uname -r) Linux kernel")
    CATEGORY_ISSUES["PCI Devices"]=$(lookup_known_issues "PCI" "PCIe device Linux driver")
    CATEGORY_ISSUES["USB Devices"]=$(lookup_known_issues "USB" "USB device Linux driver")
    CATEGORY_ISSUES["Temperatures & Fans"]=$(lookup_known_issues "Temps" "thermal fan Linux kernel")
    
    debug_log "Categories initialized. Total: ${#CATEGORIES[@]}"
}

################################################################################
# UI Functions
################################################################################
draw_menu() {
    clear
    print_title
    echo ""
    echo -e "${DIM}Use ↑/↓ or j/k to navigate, Enter to view details, Q to quit${NC}"
    if [ "$DEBUG" = true ]; then
        echo -e "${DIM}Debug mode enabled - log at: $DEBUG_LOG${NC}"
    fi
    echo ""
    
    debug_log "Drawing menu. Selected: $SELECTED"
    
    for i in "${!CATEGORIES[@]}"; do
        if [ "$i" -eq "$SELECTED" ]; then
            echo -e "${BG_CYAN}${WHITE}${BOLD} ▶ ${CATEGORIES[$i]} ${NC}"
        else
            echo -e "   ${CATEGORIES[$i]}"
        fi
    done
}

show_detail() {
    local category="${CATEGORIES[$SELECTED]}"
    local data="${CATEGORY_DATA[$category]}"
    local issues="${CATEGORY_ISSUES[$category]}"

    debug_log "Showing detail for: $category"

    # Reset link list for this view — links are re-populated per category
    JACKASS_LINKS=()

    clear
    print_title
    echo ""
    echo -e "${CYAN}${BOLD}$category - Detailed View${NC}"
    echo ""

    print_box "Hardware Information" "$data"
    echo ""
    print_box "Known Issues & Compatibility" "$issues"

    echo ""

    # ── Link open menu (desktop Linux only) ──────────────────────────────────
    if is_desktop_linux && [ ${#JACKASS_LINKS[@]} -gt 0 ]; then
        echo -e "${BOLD}── Open Vulnerability Links ──${NC}"
        for i in "${!JACKASS_LINKS[@]}"; do
            local num=$((i+1))
            echo -e "  ${CYAN}[${num}]${NC} ${JACKASS_LINKS[$i]}"
        done
        echo -e "  ${CYAN}[A]${NC} Open all links"
        echo ""
        echo -e "${DIM}Press a link number to open in browser, A for all, or any other key to return...${NC}"

        local key
        IFS= read -rsn1 key
        debug_key "$key"

        case "$key" in
            [1-9])
                local idx=$((key-1))
                if [ $idx -lt ${#JACKASS_LINKS[@]} ]; then
                    tput cnorm
                    open_url "${JACKASS_LINKS[$idx]}"
                    sleep 1
                    tput civis
                fi
                ;;
            a|A)
                tput cnorm
                for link in "${JACKASS_LINKS[@]}"; do
                    open_url "$link"
                    sleep 0.3
                done
                sleep 1
                tput civis
                ;;
            *)
                # Any other key — just return
                ;;
        esac
    else
        # Non-desktop or no links: simple keypress to return
        if [ ${#JACKASS_LINKS[@]} -gt 0 ] && ! is_desktop_linux; then
            echo -e "${DIM}Tip: Run jackass from a desktop session to open CVE links in browser.${NC}"
            echo ""
        fi
        echo -e "${DIM}Press any key to return to menu...${NC}"
        read -n 1 -s
    fi
}

################################################################################
# Main Interactive Loop
################################################################################
interactive_mode() {
    debug_init
    debug_log "Starting interactive mode"
    debug_log "Terminal type: $TERM"
    
    tput civis
    trap 'tput cnorm; clear; debug_log "Trap triggered - exiting"; exit 0' EXIT INT TERM
    
    init_categories
    
    while true; do
        draw_menu
        
        # Read single character
        IFS= read -rsn1 key
        debug_key "$key"
        
        # Check for escape sequence (arrow keys)
        if [[ $key == $'\x1b' ]]; then
            debug_log "Escape sequence detected"
            IFS= read -rsn2 -t 0.1 rest
            key="$key$rest"
            debug_log "Full escape sequence: $(echo -n "$key" | xxd -p)"
        fi
        
        debug_log "Processing key..."
        
        case "$key" in
            $'\x1b[A')
                debug_log "Arrow UP detected"
                SELECTED=$((SELECTED - 1))
                if [ $SELECTED -lt 0 ]; then
                    SELECTED=$((${#CATEGORIES[@]} - 1))
                fi
                debug_log "New selection: $SELECTED"
                ;;
            $'\x1b[B')
                debug_log "Arrow DOWN detected"
                SELECTED=$((SELECTED + 1))
                if [ $SELECTED -ge ${#CATEGORIES[@]} ]; then
                    SELECTED=0
                fi
                debug_log "New selection: $SELECTED"
                ;;
            k|K)
                debug_log "k key (UP) detected"
                SELECTED=$((SELECTED - 1))
                if [ $SELECTED -lt 0 ]; then
                    SELECTED=$((${#CATEGORIES[@]} - 1))
                fi
                debug_log "New selection: $SELECTED"
                ;;
            j|J)
                debug_log "j key (DOWN) detected"
                SELECTED=$((SELECTED + 1))
                if [ $SELECTED -ge ${#CATEGORIES[@]} ]; then
                    SELECTED=0
                fi
                debug_log "New selection: $SELECTED"
                ;;
            "")
                debug_log "Enter key detected - showing detail"
                show_detail
                ;;
            q|Q)
                debug_log "Quit key detected"
                tput cnorm
                clear
                echo "Thank you for using JACKASS!"
                if [ "$DEBUG" = true ]; then
                    echo ""
                    echo "Debug log saved to: $DEBUG_LOG"
                fi
                exit 0
                ;;
            *)
                debug_log "Unknown key: '$key' (hex: $(echo -n "$key" | xxd -p))"
                ;;
        esac
    done
}

################################################################################
# Help and Version
################################################################################
show_help() {
    echo "JACKASS - Jack of all trades Advanced Spec Sheet v${SCRIPT_VERSION}"
    echo "Author/Owner: CYBERACQ"
    echo "GitHub: https://github.com/cyberacq/jackass"
    echo ""
    echo "USAGE: ${SCRIPT_NAME} [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help           Show this help"
    echo "  -v, --version        Show version"
    echo "  -c, --compatibility  Check dependencies"
    echo "  --debug              Enable debug mode with logging"
    echo ""
    echo "INTERACTIVE CONTROLS:"
    echo "  ↑/k                  Move selection up"
    echo "  ↓/j                  Move selection down"
    echo "  Enter                View details"
    echo "  q/Q                  Quit"
    echo ""
    exit 0
}

show_version() {
    echo "JACKASS v${SCRIPT_VERSION} — CYBERACQ"
    echo "https://github.com/cyberacq/jackass"
    exit 0
}

################################################################################
# Argument Parsing
################################################################################
case "$1" in
    --debug)
        DEBUG=true
        echo "Debug mode enabled - log will be at: $DEBUG_LOG"
        sleep 1
        interactive_mode
        ;;
    -h|--help)
        show_help
        ;;
    -v|--version)
        show_version
        ;;
    -c|--compatibility)
        check_dependencies
        ;;
    "")
        interactive_mode
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

exit 0
JACKASS_EOF
    
    install -m 755 -o root -g root /tmp/jackass "$INSTALL_DIR/jackass"
    rm /tmp/jackass
    
    stop_spinner "success" "JACKASS executable created"
}

install_manpage() {
    start_spinner "Installing manual page..."
    sleep 1.0
    
    mkdir -p "$MANPAGE_DIR"
    
    cat << 'MANPAGE_EOF' | gzip > /tmp/jackass.1.gz
.TH jackass 1 "January 2026" "Version 1.2" "User Commands"
.SH NAME
jackass \- Jack of all trades Advanced Spec Sheet
.SH SYNOPSIS
.B jackass
[\fIOPTIONS\fR]
.SH DESCRIPTION
.B jackass
is an interactive hardware and system information viewer with issue detection.
.SH OPTIONS
.TP
.BR \-h ", " \-\-help
Display help
.TP
.BR \-v ", " \-\-version
Display version
.TP
.BR \-c ", " \-\-compatibility
Check dependencies
.TP
.BR \-\-debug
Enable debug mode with detailed logging
.SH INTERACTIVE CONTROLS
.TP
.BR ↑ ", " k
Move selection up
.TP
.BR ↓ ", " j
Move selection down
.TP
.BR Enter
View details
.TP
.BR q ", " Q
Quit
.SH FILES
.TP
.I /tmp/jackass-debug.log
Debug log file (when --debug is enabled)
.SH AUTHOR
CYBERACQ \- https://github.com/cyberacq/jackass
MANPAGE_EOF
    
    install -m 644 -o root -g root /tmp/jackass.1.gz "$MANPAGE_DIR/jackass.1.gz"
    rm /tmp/jackass.1.gz
    
    if command -v mandb > /dev/null 2>&1; then
        mandb -q 2>/dev/null || true
    fi
    
    stop_spinner "success" "Manual page installed"
}

main() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗${NC} This installer must be run with sudo"
        exit 1
    fi
    
    echo ""
    print_header "JACKASS - Jack of all trades Advanced Spec Sheet v1.2 - Installer"
    echo ""
    
    debug_log "Starting installation..."
    
    install_jackass
    install_manpage
    
    echo ""
    print_header "Installation Complete!"
    echo ""
    echo "JACKASS has been successfully installed!"
    echo ""
    echo "Usage:"
    echo "  jackass                      - Launch viewer"
    echo "  jackass --compatibility      - Check dependencies"
    echo "  jackass --help               - Show help"
    echo "  jackass --debug              - Run with debug logging"
    echo "  man jackass                  - Read manual"
    echo ""
    echo ""
    
    if [ "$DEBUG" = true ]; then
        debug_log "Installation completed successfully"
    fi
}

################################################################################
# Main Entry Point
################################################################################
case "$1" in
    --debug)
        DEBUG=true
        echo "Installer debug mode enabled"
        main
        ;;
    -h|--help)
        show_help
        ;;
    -v|--version)
        show_version
        ;;
    -c|--compatibility)
        check_installer_deps
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

exit 0
