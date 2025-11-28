#!/bin/bash

# ============================================
# BENCHMARKPRO v3.0 - Professional Edition
# System Performance Analysis Suite
# ============================================

set -e

# ============================================
# MODERN COLOR SCHEME
# ============================================

# Primary Colors
PRIMARY='\033[38;5;75m'      # Bright Blue
SECONDARY='\033[38;5;141m'   # Purple
ACCENT='\033[38;5;214m'      # Orange
SUCCESS='\033[38;5;42m'      # Green
WARNING='\033[38;5;220m'     # Yellow
ERROR='\033[38;5;196m'       # Red
INFO='\033[38;5;45m'         # Cyan

# Neutral Colors
BG_DARK='\033[48;5;233m'     # Dark Background
BG_LIGHT='\033[48;5;235m'    # Light Background
TEXT_DIM='\033[38;5;245m'    # Dim Text
TEXT_NORMAL='\033[38;5;255m' # Normal Text
TEXT_BRIGHT='\033[38;5;231m' # Bright Text

# Styles
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
NC='\033[0m'

# Modern Icons
ICON_ROCKET="🚀"
ICON_CHART="📊"
ICON_CPU="⚡"
ICON_RAM="💎"
ICON_DISK="💿"
ICON_GPU="🎮"
ICON_CHECK="✓"
ICON_CROSS="✗"
ICON_INFO="ℹ"
ICON_WARN="⚠"
ICON_STAR="★"
ICON_TROPHY="🏆"
ICON_FIRE="🔥"
ICON_SPARKLE="✨"

# ============================================
# GLOBAL VARIABLES
# ============================================

CPU_SCORE=0
RAM_SCORE=0
DISK_SCORE=0
GPU_SCORE=0
FINAL_SCORE=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
REPORTS_DIR="$SCRIPT_DIR/reports"

mkdir -p "$RESULTS_DIR" "$REPORTS_DIR"

# ============================================
# MODERN UI UTILITIES
# ============================================

# Clear screen and prepare for rendering
prepare_screen() {
    clear
    echo -e "\033[H\033[2J\033[3J"  # Clear thoroughly
}

# Modern section separator
section_divider() {
    echo -e "\n${TEXT_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Modern box drawing
draw_box_top() {
    local width=${1:-70}
    echo -e "${PRIMARY}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
}

draw_box_middle() {
    local width=${1:-70}
    echo -e "${PRIMARY}╠$(printf '═%.0s' $(seq 1 $width))╣${NC}"
}

draw_box_bottom() {
    local width=${1:-70}
    echo -e "${PRIMARY}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
}

draw_box_line() {
    local text="$1"
    local width=${2:-70}
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${PRIMARY}║${NC}%*s${TEXT_BRIGHT}${BOLD}%s${NC}%*s${PRIMARY}║${NC}\n" \
        $padding "" "$text" $((width - padding - ${#text})) ""
}

draw_box_empty() {
    local width=${1:-70}
    printf "${PRIMARY}║${NC}%*s${PRIMARY}║${NC}\n" $width ""
}

# Modern header with gradient effect
show_modern_header() {
    local title="$1"
    local subtitle="$2"
    
    prepare_screen
    echo ""
    draw_box_top 72
    draw_box_empty 72
    draw_box_line "$title" 72
    if [ -n "$subtitle" ]; then
        echo -e "${PRIMARY}║${NC}$(printf '%*s' 36 '')${TEXT_DIM}${subtitle}${NC}$(printf '%*s' $((36 - ${#subtitle})) '')${PRIMARY}║${NC}"
    fi
    draw_box_empty 72
    draw_box_bottom 72
    echo ""
}

# Modern progress bar with percentage
modern_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Color based on progress
    local color=$ERROR
    if [ $percentage -gt 66 ]; then
        color=$SUCCESS
    elif [ $percentage -gt 33 ]; then
        color=$WARNING
    fi
    
    printf "\r  ${TEXT_DIM}Progress${NC} ${color}["
    printf "%${filled}s" | tr ' ' '█'
    printf "${TEXT_DIM}%${empty}s${color}]${NC} ${TEXT_BRIGHT}${BOLD}%3d%%${NC}" "$empty" $percentage
}

# Modern spinner animation
show_spinner() {
    local pid=$1
    local message=$2
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r  ${PRIMARY}${frames[$frame]}${NC} ${TEXT_NORMAL}%s${NC}" "$message"
        frame=$(( (frame + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    
    printf "\r  ${SUCCESS}${ICON_CHECK}${NC} ${TEXT_NORMAL}%s${NC}\n" "$message"
}

# Modern status messages
print_status() {
    local level=$1
    local message=$2
    local icon color
    
    case $level in
        "success")
            icon=$ICON_CHECK
            color=$SUCCESS
            ;;
        "error")
            icon=$ICON_CROSS
            color=$ERROR
            ;;
        "warning")
            icon=$ICON_WARN
            color=$WARNING
            ;;
        "info")
            icon=$ICON_INFO
            color=$INFO
            ;;
        *)
            icon="•"
            color=$TEXT_NORMAL
            ;;
    esac
    
    echo -e "  ${color}${icon}${NC} ${TEXT_NORMAL}${message}${NC}"
}

# Modern metric display
show_metric() {
    local label=$1
    local value=$2
    local unit=$3
    local icon=$4
    
    printf "  ${icon} ${TEXT_DIM}%-20s${NC} ${TEXT_BRIGHT}${BOLD}%s${NC} ${TEXT_DIM}%s${NC}\n" \
        "$label" "$value" "$unit"
}

# Modern score card
show_score_card() {
    local title=$1
    local score=$2
    local max=$3
    local icon=$4
    
    score=$(validate_number "$score" 0)
    local percentage=$(safe_calc "($score * 100) / $max" 0)
    percentage=${percentage%.*}
    
    # Determine color and grade
    local color grade
    if [ $percentage -ge 90 ]; then
        color=$SUCCESS
        grade="S"
    elif [ $percentage -ge 80 ]; then
        color=$SUCCESS
        grade="A"
    elif [ $percentage -ge 70 ]; then
        color=$INFO
        grade="B"
    elif [ $percentage -ge 60 ]; then
        color=$WARNING
        grade="C"
    elif [ $percentage -ge 50 ]; then
        color=$WARNING
        grade="D"
    else
        color=$ERROR
        grade="F"
    fi
    
    # Draw score card
    echo -e "\n${PRIMARY}╭────────────────────────────────────────────────╮${NC}"
    printf "${PRIMARY}│${NC} ${icon}  ${TEXT_BRIGHT}${BOLD}%-20s${NC}" "$title"
    printf "        ${color}${BOLD}Grade: %s${NC}  ${PRIMARY}│${NC}\n" "$grade"
    echo -e "${PRIMARY}├────────────────────────────────────────────────┤${NC}"
    
    # Score bar
    local bar_width=40
    local filled=$(safe_calc "($percentage * $bar_width) / 100" 0)
    filled=${filled%.*}
    local empty=$((bar_width - filled))
    
    printf "${PRIMARY}│${NC}  ${color}"
    [ $filled -gt 0 ] && printf "%${filled}s" | tr ' ' '▰'
    [ $empty -gt 0 ] && printf "${TEXT_DIM}%${empty}s" | tr ' ' '▱'
    printf "${NC}  ${PRIMARY}│${NC}\n"
    
    # Score value
    printf "${PRIMARY}│${NC}  ${TEXT_DIM}Score:${NC} ${color}${BOLD}%.1f${NC}${TEXT_DIM}/%d${NC}" "$score" "$max"
    printf "  ${TEXT_DIM}(${NC}${color}${BOLD}%d%%${NC}${TEXT_DIM})${NC}" $percentage
    printf "          ${PRIMARY}│${NC}\n"
    echo -e "${PRIMARY}╰────────────────────────────────────────────────╯${NC}"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

validate_number() {
    local num=$1
    local default=${2:-0}
    num=$(echo "$num" | tr -d ' ')
    if [[ -z "$num" ]] || ! [[ "$num" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "$default"
        return
    fi
    echo "$num"
}

safe_calc() {
    local expression=$1
    local default=${2:-0}
    local result=$(echo "$expression" | bc 2>/dev/null)
    if [[ -z "$result" ]] || ! [[ "$result" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo "$default"
        return
    fi
    echo "$result"
}

pause() {
    echo ""
    echo -ne "${TEXT_DIM}Press ${NC}${TEXT_BRIGHT}[ENTER]${NC}${TEXT_DIM} to continue...${NC}"
    read
}

# ============================================
# DEPENDENCY MANAGEMENT
# ============================================

check_dependencies() {
    show_modern_header "Dependency Check" "Verifying system requirements"
    
    local deps=("sysbench" "fio" "glxinfo" "bc" "jq")
    local missing=()
    
    echo -e "${TEXT_BRIGHT}${BOLD}Required Tools${NC}\n"
    
    for dep in "${deps[@]}"; do
        if command -v $dep &> /dev/null; then
            print_status "success" "$(printf '%-20s' "$dep") installed"
        else
            print_status "error" "$(printf '%-20s' "$dep") missing"
            missing+=($dep)
        fi
        sleep 0.1
    done
    
    echo ""
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_status "warning" "${#missing[@]} dependencies missing"
        echo ""
        echo -e "${WARNING}${BOLD}Install missing dependencies?${NC} ${TEXT_DIM}(y/n)${NC} "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            install_dependencies
            return 0
        else
            print_status "error" "Cannot proceed without dependencies"
            return 1
        fi
    fi
    
    print_status "success" "All dependencies satisfied"
    sleep 1
    return 0
}

install_dependencies() {
    show_modern_header "Installing Dependencies" "Setting up benchmark tools"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        print_status "error" "Cannot detect distribution"
        return 1
    fi
    
    print_status "info" "Detected: $PRETTY_NAME"
    echo ""
    
    case $OS in
        ubuntu|debian|pop)
            print_status "info" "Using APT package manager"
            sudo apt update -qq
            sudo apt install -y sysbench fio mesa-utils jq bc
            ;;
        fedora|rhel|centos)
            print_status "info" "Using DNF package manager"
            sudo dnf install -y sysbench fio mesa-demos jq bc
            ;;
        arch|manjaro)
            print_status "info" "Using Pacman package manager"
            sudo pacman -S --noconfirm sysbench fio mesa-utils jq bc
            ;;
        *)
            print_status "error" "Unsupported distribution: $OS"
            return 1
            ;;
    esac
    
    echo ""
    print_status "success" "Installation completed successfully"
}

# ============================================
# SYSTEM INFORMATION
# ============================================

get_system_info() {
    show_modern_header "System Information" "Hardware detection and analysis"
    
    echo "=== SYSTEM INFO ===" >> "$RESULTS_FILE"
    
    # CPU Detection
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs 2>/dev/null)
    if [ -z "$CPU_MODEL" ]; then
        VENDOR=$(lscpu | grep "Vendor ID" | cut -d':' -f2 | xargs 2>/dev/null)
        CPU_MODEL="Processor ${VENDOR:-Unknown}"
    fi
    
    CPU_THREADS=$(nproc)
    CPU_CORES=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}' 2>/dev/null)
    [ -z "$CPU_CORES" ] && CPU_CORES=$CPU_THREADS
    
    CPU_FREQ=$(lscpu | grep "CPU max MHz" | awk '{print $4}' 2>/dev/null)
    CPU_FREQ=$(echo "scale=2; ${CPU_FREQ:-0} / 1000" | bc)
    
    # Memory Detection
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    RAM_SPEED=$(sudo dmidecode -t memory 2>/dev/null | grep "Speed:" | head -1 | awk '{print $2" "$3}' || echo "Unknown")
    
    # GPU Detection
    GPU_INFO=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | cut -d':' -f3 | xargs | head -1)
    [ -z "$GPU_INFO" ] && GPU_INFO="Integrated Graphics"
    
    # Storage Detection
    DISK_INFO=$(lsblk -d -o NAME,SIZE,TYPE 2>/dev/null | grep disk | head -1 | awk '{print $2}')
    
    # Display information
    echo -e "${TEXT_BRIGHT}${BOLD}Hardware Configuration${NC}\n"
    
    echo -e "${PRIMARY}┌─ Processor ──────────────────────────────────┐${NC}"
    show_metric "Model" "$CPU_MODEL" "" "$ICON_CPU"
    show_metric "Cores / Threads" "${CPU_CORES} / ${CPU_THREADS}" "" ""
    [ "$CPU_FREQ" != "0" ] && show_metric "Max Frequency" "$CPU_FREQ" "GHz" ""
    echo -e "${PRIMARY}└──────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${PRIMARY}┌─ Memory ─────────────────────────────────────┐${NC}"
    show_metric "Total RAM" "$RAM_TOTAL" "" "$ICON_RAM"
    show_metric "Speed" "$RAM_SPEED" "" ""
    echo -e "${PRIMARY}└──────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${PRIMARY}┌─ Graphics ───────────────────────────────────┐${NC}"
    show_metric "GPU" "$GPU_INFO" "" "$ICON_GPU"
    echo -e "${PRIMARY}└──────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${PRIMARY}┌─ Storage ────────────────────────────────────┐${NC}"
    show_metric "Primary Drive" "$DISK_INFO" "" "$ICON_DISK"
    echo -e "${PRIMARY}└──────────────────────────────────────────────┘${NC}"
    
    {
        echo "CPU: $CPU_MODEL ($CPU_CORES cores / $CPU_THREADS threads)"
        echo "RAM: $RAM_TOTAL ($RAM_SPEED)"
        echo "GPU: $GPU_INFO"
        echo "Storage: $DISK_INFO"
        echo ""
    } >> "$RESULTS_FILE"
    
    sleep 2
}

# ============================================
# BENCHMARK TESTS
# ============================================

test_cpu() {
    show_modern_header "CPU Benchmark" "Testing processing power"
    
    echo "=== CPU BENCHMARK ===" >> "$RESULTS_FILE"
    
    # Single-thread test
    print_status "info" "Running single-thread test..."
    echo ""
    
    sysbench cpu --cpu-max-prime=20000 --threads=1 run > /tmp/cpu_single.txt 2>&1 &
    show_spinner $! "Computing prime numbers (single-core)"
    
    local single_result=$(grep "events per second" /tmp/cpu_single.txt | awk '{print $4}')
    single_result=$(validate_number "$single_result" 100)
    
    show_metric "Single-thread" "$(printf "%.2f" $single_result)" "events/sec" "$ICON_CPU"
    echo ""
    
    # Multi-thread test
    print_status "info" "Running multi-thread test ($CPU_THREADS threads)..."
    echo ""
    
    sysbench cpu --cpu-max-prime=20000 --threads=$CPU_THREADS run > /tmp/cpu_multi.txt 2>&1 &
    show_spinner $! "Computing prime numbers (multi-core)"
    
    local multi_result=$(grep "events per second" /tmp/cpu_multi.txt | awk '{print $4}')
    multi_result=$(validate_number "$multi_result" 500)
    
    show_metric "Multi-thread" "$(printf "%.2f" $multi_result)" "events/sec" "$ICON_CPU"
    
    # Calculate score
    local single_score=$(safe_calc "($single_result / 2000) * 50" 0)
    local multi_score=$(safe_calc "($multi_result / 16000) * 50" 0)
    CPU_SCORE=$(safe_calc "$single_score + $multi_score" 0)
    
    local cpu_int=${CPU_SCORE%.*}
    [ $cpu_int -gt 100 ] && CPU_SCORE=100
    
    show_score_card "CPU Performance" "$CPU_SCORE" "100" "$ICON_CPU"
    
    {
        echo "Single-thread: $single_result events/sec"
        echo "Multi-thread: $multi_result events/sec"
        echo "CPU: ${CPU_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    rm -f /tmp/cpu_*.txt
    sleep 1
}

test_ram() {
    show_modern_header "Memory Benchmark" "Testing RAM bandwidth"
    
    echo "=== RAM BENCHMARK ===" >> "$RESULTS_FILE"
    
    print_status "info" "Running memory bandwidth test..."
    echo ""
    
    sysbench memory --memory-block-size=1M --memory-total-size=10G --threads=4 run > /tmp/ram_test.txt 2>&1 &
    show_spinner $! "Measuring memory throughput"
    
    local mem_speed=$(grep "transferred" /tmp/ram_test.txt | grep -oP '\d+\.\d+' | head -1)
    [ -z "$mem_speed" ] && mem_speed=$(grep "MiB/sec" /tmp/ram_test.txt | awk '{print $(NF-1)}' | head -1)
    mem_speed=$(validate_number "$mem_speed" 1000)
    
    show_metric "Bandwidth" "$(printf "%.2f" $mem_speed)" "MiB/sec" "$ICON_RAM"
    
    RAM_SCORE=$(safe_calc "($mem_speed / 10000) * 100" 0)
    local ram_int=${RAM_SCORE%.*}
    [ $ram_int -gt 100 ] && RAM_SCORE=100
    
    show_score_card "Memory Performance" "$RAM_SCORE" "100" "$ICON_RAM"
    
    {
        echo "Bandwidth: $mem_speed MiB/sec"
        echo "RAM: ${RAM_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    rm -f /tmp/ram_test.txt
    sleep 1
}

test_disk() {
    show_modern_header "Storage Benchmark" "Testing I/O performance"
    
    echo "=== DISK BENCHMARK ===" >> "$RESULTS_FILE"
    
    local test_dir="$SCRIPT_DIR/benchmark_disk_test"
    mkdir -p "$test_dir"
    
    print_status "info" "Creating test files (~2GB)..."
    echo ""
    
    # Sequential write
    print_status "info" "Testing sequential write..."
    fio --name=seq_write --directory="$test_dir" --rw=write --bs=1M --size=1G \
        --numjobs=1 --runtime=20 --time_based --group_reporting \
        --output-format=json > /tmp/fio_write.json 2>&1 &
    show_spinner $! "Writing sequential data"
    
    local seq_write=$(jq -r '.jobs[0].write.bw_bytes' /tmp/fio_write.json 2>/dev/null)
    seq_write=$(validate_number "$seq_write" 10485760)
    seq_write=$(safe_calc "$seq_write / 1048576" 10)
    
    show_metric "Sequential Write" "$(printf "%.2f" $seq_write)" "MB/s" "$ICON_DISK"
    echo ""
    
    # Sequential read
    print_status "info" "Testing sequential read..."
    fio --name=seq_read --directory="$test_dir" --rw=read --bs=1M --size=1G \
        --numjobs=1 --runtime=20 --time_based --group_reporting \
        --output-format=json > /tmp/fio_read.json 2>&1 &
    show_spinner $! "Reading sequential data"
    
    local seq_read=$(jq -r '.jobs[0].read.bw_bytes' /tmp/fio_read.json 2>/dev/null)
    seq_read=$(validate_number "$seq_read" 20971520)
    seq_read=$(safe_calc "$seq_read / 1048576" 20)
    
    show_metric "Sequential Read" "$(printf "%.2f" $seq_read)" "MB/s" "$ICON_DISK"
    echo ""
    
    # Random IOPS
    print_status "info" "Testing random I/O operations..."
    fio --name=rand_rw --directory="$test_dir" --rw=randrw --bs=4K --size=512M \
        --numjobs=4 --runtime=15 --time_based --group_reporting \
        --output-format=json > /tmp/fio_rand.json 2>&1 &
    show_spinner $! "Measuring random IOPS"
    
    local rand_iops=$(jq -r '.jobs[0].read.iops' /tmp/fio_rand.json 2>/dev/null)
    rand_iops=$(validate_number "$rand_iops" 1000)
    rand_iops=${rand_iops%.*}
    
    show_metric "Random IOPS (4K)" "$rand_iops" "ops/sec" "$ICON_DISK"
    
    rm -rf "$test_dir"
    rm -f /tmp/fio_*.json
    
    local seq_score=$(safe_calc "($seq_read / 3000) * 50" 0)
    local iops_score=$(safe_calc "($rand_iops / 50000) * 50" 0)
    DISK_SCORE=$(safe_calc "$seq_score + $iops_score" 0)
    
    local disk_int=${DISK_SCORE%.*}
    [ $disk_int -gt 100 ] && DISK_SCORE=100
    
    show_score_card "Storage Performance" "$DISK_SCORE" "100" "$ICON_DISK"
    
    {
        echo "Write: $(printf "%.2f" $seq_write) MB/s"
        echo "Read: $(printf "%.2f" $seq_read) MB/s"
        echo "IOPS: $rand_iops"
        echo "Disk: ${DISK_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    sleep 1
}

test_gpu() {
    show_modern_header "Graphics Benchmark" "Testing GPU performance"
    
    echo "=== GPU BENCHMARK ===" >> "$RESULTS_FILE"
    
    if [ -z "$DISPLAY" ] || ! command -v glxgears &> /dev/null; then
        print_status "warning" "No display environment detected"
        GPU_SCORE=50
        echo "GPU: 50.00/100 (test skipped)" >> "$RESULTS_FILE"
        show_score_card "Graphics Performance" "$GPU_SCORE" "100" "$ICON_GPU"
        sleep 1
        return
    fi
    
    print_status "info" "Running OpenGL rendering test..."
    echo ""
    
    timeout 11s glxgears 2>&1 | tee /tmp/glxgears.log &
    local pid=$!
    show_spinner $pid "Rendering 3D graphics"
    
    local fps=$(grep "frames in" /tmp/glxgears.log | tail -1 | awk '{print $6}' | tr -d ' ')
    fps=$(validate_number "$fps" 500)
    
    show_metric "OpenGL FPS" "$(printf "%.0f" $fps)" "frames/sec" "$ICON_GPU"
    
    GPU_SCORE=$(safe_calc "($fps / 2000) * 100" 0)
    local gpu_int=${GPU_SCORE%.*}
    [ $gpu_int -gt 100 ] && GPU_SCORE=100
    
    show_score_card "Graphics Performance" "$GPU_SCORE" "100" "$ICON_GPU"
    
    {
        echo "FPS: $(printf "%.0f" $fps)"
        echo "GPU: ${GPU_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    rm -f /tmp/glxgears.log
    sleep 1
}

# ============================================
# FINAL RESULTS
# ============================================

calculate_final_score() {
    show_modern_header "Results Analysis" "Computing final performance score"
    
    print_status "info" "Analyzing benchmark results..."
    sleep 1
    
    # Validate all scores
    CPU_SCORE=$(validate_number "$CPU_SCORE" 0)
    RAM_SCORE=$(validate_number "$RAM_SCORE" 0)
    DISK_SCORE=$(validate_number "$DISK_SCORE" 0)
    GPU_SCORE=$(validate_number "$GPU_SCORE" 0)
    
    FINAL_SCORE=$(safe_calc "($CPU_SCORE * 0.35) + ($RAM_SCORE * 0.20) + ($DISK_SCORE * 0.30) + ($GPU_SCORE * 0.15)" 0)
    
    echo ""
    draw_box_top 72
    draw_box_empty 72
    draw_box_line "PERFORMANCE SCORECARD" 72
    draw_box_empty 72
    draw_box_middle 72
    
    print_component_score() {
        local icon=$1
        local name=$2
        local score=$3
        local weight=$4
        
        score=$(validate_number "$score" 0)
        local int_score=${score%.*}
        
        local color=$ERROR
        [ $int_score -gt 70 ] && color=$SUCCESS
        [ $int_score -gt 40 ] && [ $int_score -le 70 ] && color=$WARNING
        
        local bar_length=30
        local filled=$(safe_calc "($int_score * $bar_length) / 100" 0)
        filled=${filled%.*}
        local empty=$((bar_length - filled))
        
        printf "${PRIMARY}║${NC}  ${icon}  ${TEXT_BRIGHT}%-12s${NC} " "$name"
        printf "${color}"
        [ $filled -gt 0 ] && printf "%${filled}s" | tr ' ' '▰'
        [ $empty -gt 0 ] && printf "${TEXT_DIM}%${empty}s${NC}" | tr ' ' '▱'
        printf "${NC}  ${color}${BOLD}%5.1f${NC}${TEXT_DIM}/100${NC} ${TEXT_DIM}(%s)${NC}  ${PRIMARY}║${NC}\n" "$score" "$weight"
    }
    
    print_component_score "$ICON_CPU" "CPU" "$CPU_SCORE" "35%"
    print_component_score "$ICON_RAM" "Memory" "$RAM_SCORE" "20%"
    print_component_score "$ICON_DISK" "Storage" "$DISK_SCORE" "30%"
    print_component_score "$ICON_GPU" "Graphics" "$GPU_SCORE" "15%"
    
    draw_box_middle 72
    draw_box_empty 72
    
    # Determine category
    local int_final=${FINAL_SCORE%.*}
    [ -z "$int_final" ] && int_final=0
    
    local final_color category cat_icon
    
    if [ $int_final -ge 90 ]; then
        final_color=$SUCCESS
        category="EXCEPTIONAL"
        cat_icon="$ICON_TROPHY"
    elif [ $int_final -ge 80 ]; then
        final_color=$SUCCESS
        category="EXCELLENT"
        cat_icon="$ICON_FIRE"
    elif [ $int_final -ge 70 ]; then
        final_color=$INFO
        category="VERY GOOD"
        cat_icon="$ICON_SPARKLE"
    elif [ $int_final -ge 60 ]; then
        final_color=$INFO
        category="GOOD"
        cat_icon="$ICON_STAR"
    elif [ $int_final -ge 50 ]; then
        final_color=$WARNING
        category="AVERAGE"
        cat_icon="•"
    else
        final_color=$ERROR
        category="BELOW AVERAGE"
        cat_icon="$ICON_WARN"
    fi
    
    printf "${PRIMARY}║${NC}$(printf '%*s' 25 '')${TEXT_BRIGHT}${BOLD}FINAL SCORE${NC}$(printf '%*s' 36 '')${PRIMARY}║${NC}\n"
    printf "${PRIMARY}║${NC}$(printf '%*s' 24 '')${final_color}${BOLD}%.2f${NC}${TEXT_DIM} / 100${NC}$(printf '%*s' 34 '')${PRIMARY}║${NC}\n" "$FINAL_SCORE"
    draw_box_empty 72
    printf "${PRIMARY}║${NC}$(printf '%*s' 22 '')${cat_icon}  ${final_color}${BOLD}%-15s${NC}$(printf '%*s' 32 '')${PRIMARY}║${NC}\n" "$category"
    draw_box_empty 72
    draw_box_bottom 72
    
    {
        echo "=== FINAL SCORES ==="
        echo "CPU: ${CPU_SCORE}/100"
        echo "RAM: ${RAM_SCORE}/100"
        echo "Disk: ${DISK_SCORE}/100"
        echo "GPU: ${GPU_SCORE}/100"
        echo "FINAL: ${FINAL_SCORE}/100"
        echo "Category: $category"
    } >> "$RESULTS_FILE"
    
    sleep 2
}

# ============================================
# MAIN BENCHMARK RUNNER
# ============================================

run_benchmark() {
    prepare_screen
    
    # ASCII Art Banner
    echo -e "${PRIMARY}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║   ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗██████╗ ██████╗  ██████╗ ║
    ║   ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗║
    ║   ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██████╔╝██████╔╝██║   ██║║
    ║   ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██╔═══╝ ██╔══██╗██║   ██║║
    ║   ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║     ██║  ██║╚██████╔╝║
    ║   ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ║
    ║                                                                      ║
    ║              Professional System Performance Analysis                ║
    ║                           Version 3.0                                ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    section_divider
    
    echo -e "${INFO}${ICON_ROCKET} ${TEXT_BRIGHT}${BOLD}Initializing benchmark suite...${NC}\n"
    echo -e "${TEXT_DIM}  Estimated duration: ${NC}${TEXT_NORMAL}5-10 minutes${NC}"
    echo -e "${TEXT_DIM}  Close resource-intensive applications for optimal results${NC}"
    
    section_divider
    
    pause
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    RESULTS_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}.txt"
    
    check_dependencies || return
    get_system_info
    test_cpu
    test_ram
    test_disk
    test_gpu
    calculate_final_score
    
    show_modern_header "Benchmark Complete" "Results saved successfully"
    
    print_status "success" "Results file: benchmark_${TIMESTAMP}.txt"
    echo ""
    echo -e "${TEXT_DIM}  Location: ${NC}${TEXT_BRIGHT}$RESULTS_FILE${NC}"
    
    section_divider
}

# ============================================
# MENU SYSTEM
# ============================================

show_menu() {
    prepare_screen
    
    echo -e "${PRIMARY}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║                        BENCHMARKPRO v3.0                             ║
    ║                  Professional Performance Suite                      ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    # Show latest result if available
    if [ -d "$RESULTS_DIR" ]; then
        local latest=$(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            local score=$(grep "FINAL:" "$latest" | grep -oP '\d+\.\d+' | head -1)
            score=$(validate_number "$score" 0)
            local date=$(basename "$latest" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ @ /')
            
            if [ -n "$score" ]; then
                local int_score=${score%.*}
                local color=$ERROR
                [ $int_score -gt 70 ] && color=$SUCCESS
                [ $int_score -gt 40 ] && [ $int_score -le 70 ] && color=$WARNING
                
                echo -e "${TEXT_DIM}  Latest: ${NC}${TEXT_NORMAL}$date${NC}"
                echo -e "${TEXT_DIM}  Score:  ${color}${BOLD}$(printf "%.1f" $score)${NC}${TEXT_DIM}/100${NC}\n"
            fi
        fi
    fi
    
    section_divider
    
    echo -e "${TEXT_BRIGHT}${BOLD}Main Menu${NC}\n"
    echo -e "  ${SUCCESS}1.${NC} ${ICON_ROCKET} ${TEXT_NORMAL}Run System Benchmark${NC}"
    echo -e "  ${INFO}2.${NC} ${ICON_CHART} ${TEXT_NORMAL}Compare Results${NC}"
    echo -e "  ${SECONDARY}3.${NC} 📄 ${TEXT_NORMAL}Generate HTML Report${NC}"
    echo -e "  ${WARNING}4.${NC} 📋 ${TEXT_NORMAL}View History${NC}"
    echo -e "  ${ACCENT}5.${NC} 📖 ${TEXT_NORMAL}Optimization Guide${NC}"
    echo -e "  ${PRIMARY}6.${NC} 🔧 ${TEXT_NORMAL}Install Dependencies${NC}"
    echo -e "  ${ERROR}0.${NC} ❌ ${TEXT_NORMAL}Exit${NC}"
    
    section_divider
}

# ============================================
# MAIN ENTRY POINT
# ============================================

main() {
    while true; do
        show_menu
        echo -ne "${PRIMARY}${BOLD}➜${NC} ${TEXT_NORMAL}Select option: ${NC}"
        read choice
        
        case $choice in
            1) run_benchmark; pause ;;
            2) echo -e "\n${INFO}Feature coming soon...${NC}"; sleep 2 ;;
            3) echo -e "\n${INFO}Feature coming soon...${NC}"; sleep 2 ;;
            4) echo -e "\n${INFO}Feature coming soon...${NC}"; sleep 2 ;;
            5) echo -e "\n${INFO}Feature coming soon...${NC}"; sleep 2 ;;
            6) install_dependencies; pause ;;
            0)
                prepare_screen
                echo ""
                echo -e "${SUCCESS}${ICON_CHECK}${NC} ${TEXT_BRIGHT}Thank you for using BenchmarkPro${NC}\n"
                echo -e "${TEXT_DIM}  Results saved in: ${NC}${TEXT_NORMAL}$RESULTS_DIR${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${ERROR}${ICON_CROSS}${NC} ${TEXT_NORMAL}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Launch application
main