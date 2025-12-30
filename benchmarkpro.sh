#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                         SYSTEMBENCH PRO v1.2                              ║
# ║              Professional System Performance Analysis Suite               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Force C locale for numeric operations (fixes French locale issues)
export LC_NUMERIC=C
export LC_ALL=C

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly VERSION="1.2.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DATA_DIR="$SCRIPT_DIR/data"
readonly RESULTS_DIR="$SCRIPT_DIR/results"
readonly REPORTS_DIR="$SCRIPT_DIR/reports"
readonly TEMP_DIR="/tmp/systembench_$$"

# Test configuration
WARMUP_ITERATIONS=2
TEST_ITERATIONS=3

# Reference scores (baseline: Intel i5-10400 @ 2.9GHz, 16GB DDR4-2666, SATA SSD)
REF_CPU_SINGLE=1000
REF_CPU_MULTI=6000
REF_CPU_COMPRESS=50000
REF_MEM_BANDWIDTH=15000
REF_DISK_SEQ_READ=500
REF_DISK_SEQ_WRITE=450
REF_DISK_RAND_READ=50000
REF_DISK_RAND_WRITE=40000

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

if [[ -t 1 ]]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_DIM='\033[2m'
    C_RED='\033[31m'
    C_GREEN='\033[32m'
    C_YELLOW='\033[33m'
    C_BLUE='\033[34m'
    C_CYAN='\033[36m'
else
    C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN=''
    C_YELLOW='' C_BLUE='' C_CYAN=''
fi

# ============================================================================
# LOGGING & OUTPUT
# ============================================================================

log_info()    { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
log_success() { echo -e "${C_GREEN}[PASS]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; }

print_header() {
    local title="$1"
    local width=70
    echo ""
    echo -e "${C_BOLD}${C_CYAN}┌$(printf '─%.0s' $(seq 1 $((width-2))))┐${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET} %-$((width-4))s ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$title"
    echo -e "${C_BOLD}${C_CYAN}└$(printf '─%.0s' $(seq 1 $((width-2))))┘${C_RESET}"
}

print_metric() {
    local label="$1"
    local value="$2"
    local unit="${3:-}"
    local score="${4:-}"
    
    printf "  ${C_DIM}%-25s${C_RESET} ${C_BOLD}%12s${C_RESET} %-8s" "$label" "$value" "$unit"
    
    if [[ -n "$score" && "$score" != "0" ]]; then
        local color=$C_GREEN
        local score_int=${score%%.*}
        score_int=${score_int:-0}
        [[ $score_int -lt 80 ]] && color=$C_YELLOW
        [[ $score_int -lt 50 ]] && color=$C_RED
        printf " ${color}[%5.1f%%]${C_RESET}" "$score"
    fi
    echo ""
}

print_progress() {
    local current=$1
    local total=$2
    local label="${3:-Progress}"
    local pct=$((current * 100 / total))
    local filled=$((pct / 2))
    local empty=$((50 - filled))
    
    printf "\r  ${C_DIM}%s${C_RESET} [${C_CYAN}" "$label"
    [[ $filled -gt 0 ]] && printf "%${filled}s" | tr ' ' '█'
    [[ $empty -gt 0 ]] && printf "${C_DIM}%${empty}s" | tr ' ' '░'
    printf "${C_RESET}] %3d%%" "$pct"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

init_directories() {
    mkdir -p "$DATA_DIR" "$RESULTS_DIR" "$REPORTS_DIR" "$TEMP_DIR"
}

check_dependencies() {
    local deps=("bc" "sysbench" "fio")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt install ${missing[*]}"
        return 1
    fi
    
    if ! command -v jq &>/dev/null; then
        log_warn "jq not installed - JSON parsing limited"
    fi
    
    return 0
}

# Safe arithmetic with bc
calc() {
    local result
    result=$(echo "scale=2; $*" | bc -l 2>/dev/null)
    if [[ -z "$result" || "$result" == "" ]]; then
        echo "0"
    else
        echo "$result"
    fi
}

# Calculate mean without nameref (fixes circular reference bug)
array_mean() {
    local sum=0
    local count=0
    for val in "$@"; do
        if [[ -n "$val" && "$val" =~ ^[0-9.]+$ ]]; then
            sum=$(calc "$sum + $val")
            ((count++))
        fi
    done
    [[ $count -eq 0 ]] && echo "0" && return
    calc "$sum / $count"
}

# Calculate stddev without nameref
array_stddev() {
    local mean
    mean=$(array_mean "$@")
    local sum_sq=0
    local count=0
    
    for val in "$@"; do
        if [[ -n "$val" && "$val" =~ ^[0-9.]+$ ]]; then
            local diff=$(calc "$val - $mean")
            sum_sq=$(calc "$sum_sq + ($diff * $diff)")
            ((count++))
        fi
    done
    
    [[ $count -lt 2 ]] && echo "0" && return
    calc "sqrt($sum_sq / ($count - 1))"
}

# ============================================================================
# SYSTEM INFORMATION
# ============================================================================

SYS_CPU_MODEL=""
SYS_CPU_CORES=1
SYS_CPU_THREADS=1
SYS_CPU_ARCH=""
SYS_CPU_FREQ_MAX=""
SYS_CPU_CACHE=""
SYS_MEM_TOTAL_GB=0
SYS_MEM_TYPE=""
SYS_MEM_SPEED=""
SYS_DISK_MODEL=""
SYS_DISK_SIZE=""
SYS_DISK_TYPE=""
SYS_OS_NAME=""
SYS_KERNEL=""
SYS_HOSTNAME=""

collect_system_info() {
    print_header "System Information"
    
    # CPU Information
    SYS_CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | xargs)
    [[ -z "$SYS_CPU_MODEL" ]] && SYS_CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)
    [[ -z "$SYS_CPU_MODEL" ]] && SYS_CPU_MODEL="Unknown CPU"
    
    SYS_CPU_THREADS=$(nproc 2>/dev/null || echo "1")
    
    # Physical cores = cores per socket * sockets
    local cores_per_socket sockets
    cores_per_socket=$(lscpu 2>/dev/null | grep "^Core(s) per socket:" | awk '{print $4}')
    sockets=$(lscpu 2>/dev/null | grep "^Socket(s):" | awk '{print $2}')
    cores_per_socket=${cores_per_socket:-1}
    sockets=${sockets:-1}
    SYS_CPU_CORES=$((cores_per_socket * sockets))
    
    SYS_CPU_ARCH=$(uname -m)
    SYS_CPU_FREQ_MAX=$(lscpu 2>/dev/null | grep "CPU max MHz" | awk '{print $4}')
    SYS_CPU_CACHE=$(lscpu 2>/dev/null | grep "L3 cache" | cut -d':' -f2 | xargs)
    
    # Memory
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    mem_kb=${mem_kb:-0}
    SYS_MEM_TOTAL_GB=$(calc "$mem_kb / 1024 / 1024")
    
    if command -v dmidecode &>/dev/null && [[ $EUID -eq 0 ]]; then
        SYS_MEM_SPEED=$(dmidecode -t memory 2>/dev/null | grep "Configured Memory Speed" | grep -v "Unknown" | head -1 | awk '{print $4}')
        SYS_MEM_TYPE=$(dmidecode -t memory 2>/dev/null | grep "^\s*Type:" | grep -v "Unknown\|None\|Error" | head -1 | awk '{print $2}')
    fi
    SYS_MEM_SPEED=${SYS_MEM_SPEED:-"N/A"}
    SYS_MEM_TYPE=${SYS_MEM_TYPE:-"N/A"}
    
    # Storage
    local disk_name
    disk_name=$(lsblk -d -o NAME,TYPE 2>/dev/null | grep "disk" | head -1 | awk '{print $1}')
    if [[ -n "$disk_name" ]]; then
        SYS_DISK_MODEL=$(lsblk -d -o MODEL "/dev/$disk_name" 2>/dev/null | tail -1 | xargs)
        SYS_DISK_SIZE=$(lsblk -d -o SIZE "/dev/$disk_name" 2>/dev/null | tail -1 | xargs)
        local rotational
        rotational=$(cat "/sys/block/$disk_name/queue/rotational" 2>/dev/null)
        [[ "$rotational" == "0" ]] && SYS_DISK_TYPE="SSD" || SYS_DISK_TYPE="HDD"
    else
        SYS_DISK_MODEL="Unknown"
        SYS_DISK_SIZE="Unknown"
        SYS_DISK_TYPE="Unknown"
    fi
    
    # OS
    if [[ -f /etc/os-release ]]; then
        SYS_OS_NAME=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2)
    fi
    SYS_OS_NAME=${SYS_OS_NAME:-$(uname -s)}
    SYS_KERNEL=$(uname -r)
    SYS_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    
    # Display
    echo ""
    echo -e "  ${C_BOLD}Processor${C_RESET}"
    print_metric "Model" "$SYS_CPU_MODEL"
    print_metric "Cores / Threads" "${SYS_CPU_CORES} / ${SYS_CPU_THREADS}"
    print_metric "Architecture" "$SYS_CPU_ARCH"
    if [[ -n "$SYS_CPU_FREQ_MAX" && "$SYS_CPU_FREQ_MAX" != "0" ]]; then
        print_metric "Max Frequency" "$(calc "$SYS_CPU_FREQ_MAX / 1000")" "GHz"
    fi
    [[ -n "$SYS_CPU_CACHE" ]] && print_metric "L3 Cache" "$SYS_CPU_CACHE"
    
    echo ""
    echo -e "  ${C_BOLD}Memory${C_RESET}"
    print_metric "Total" "$(printf "%.1f" "$SYS_MEM_TOTAL_GB")" "GB"
    [[ "$SYS_MEM_SPEED" != "N/A" ]] && print_metric "Speed" "$SYS_MEM_SPEED" "MT/s"
    [[ "$SYS_MEM_TYPE" != "N/A" ]] && print_metric "Type" "$SYS_MEM_TYPE"
    
    echo ""
    echo -e "  ${C_BOLD}Storage${C_RESET}"
    print_metric "Model" "$SYS_DISK_MODEL"
    print_metric "Capacity" "$SYS_DISK_SIZE"
    print_metric "Type" "$SYS_DISK_TYPE"
    
    echo ""
    echo -e "  ${C_BOLD}Operating System${C_RESET}"
    print_metric "Distribution" "$SYS_OS_NAME"
    print_metric "Kernel" "$SYS_KERNEL"
}

# ============================================================================
# PRE-TEST VALIDATION
# ============================================================================

check_system_state() {
    print_header "Pre-Test Validation"
    
    local issues=0
    
    # CPU load
    local load
    load=$(cut -d' ' -f1 /proc/loadavg)
    local cores=${SYS_CPU_CORES:-1}
    local load_pct
    load_pct=$(calc "($load / $cores) * 100")
    load_pct=${load_pct%%.*}
    
    if [[ $load_pct -gt 50 ]]; then
        log_warn "High system load: $load (${load_pct}% per core)"
        ((issues++))
    else
        log_success "System load: $load (OK)"
    fi
    
    # Memory
    local mem_available mem_total mem_pct
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_pct=$(calc "$mem_available * 100 / $mem_total")
    mem_pct=${mem_pct%%.*}
    
    if [[ $mem_pct -lt 30 ]]; then
        log_warn "Low available memory: ${mem_pct}%"
        ((issues++))
    else
        log_success "Available memory: ${mem_pct}%"
    fi
    
    # CPU frequency
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        local cur_freq max_freq freq_pct
        cur_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "0")
        max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo "0")
        
        if [[ "$max_freq" -gt 0 && "$cur_freq" -gt 0 ]]; then
            freq_pct=$(calc "$cur_freq * 100 / $max_freq")
            freq_pct=${freq_pct%%.*}
            if [[ $freq_pct -lt 80 ]]; then
                log_warn "CPU may be throttled: ${freq_pct}%"
                ((issues++))
            else
                log_success "CPU frequency: ${freq_pct}% of max"
            fi
        fi
    fi
    
    # VM detection (fixed)
    if command -v systemd-detect-virt &>/dev/null; then
        local virt
        virt=$(systemd-detect-virt 2>/dev/null)
        if [[ -n "$virt" && "$virt" != "none" ]]; then
            log_warn "Virtualized environment: $virt"
            ((issues++))
        else
            log_success "Bare metal system"
        fi
    fi
    
    # Disk space
    local free_space
    free_space=$(df "$TEMP_DIR" 2>/dev/null | tail -1 | awk '{print $4}')
    free_space=${free_space:-0}
    local free_mb=$((free_space / 1024))
    
    if [[ $free_mb -lt 5000 ]]; then
        log_warn "Low disk space: ${free_mb}MB"
        ((issues++))
    else
        log_success "Disk space: ${free_mb}MB available"
    fi
    
    echo ""
    if [[ $issues -gt 0 ]]; then
        log_warn "$issues potential issues - results may vary"
    else
        log_success "System ready"
    fi
}

# ============================================================================
# CPU BENCHMARKS
# ============================================================================

CPU_SINGLE_SCORE=0
CPU_MULTI_SCORE=0
CPU_COMPRESS_SCORE=0
CPU_AGGREGATE=0
CPU_SINGLE_RAW=0
CPU_MULTI_RAW=0
CPU_COMPRESS_RAW=0
CPU_SCALING=0

benchmark_cpu() {
    print_header "CPU Benchmark Suite"
    
    local threads=${SYS_CPU_THREADS:-$(nproc)}
    
    # Test 1: Single-thread
    echo -e "\n  ${C_BOLD}Test 1: Single-Thread Integer Performance${C_RESET}"
    log_info "Computing prime numbers (single-threaded)..."
    
    local results=()
    
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        sysbench cpu --cpu-max-prime=20000 --threads=1 run &>/dev/null
    done
    
    for ((i=1; i<=TEST_ITERATIONS; i++)); do
        print_progress $i $TEST_ITERATIONS "Iteration"
        local result
        result=$(sysbench cpu --cpu-max-prime=20000 --threads=1 run 2>/dev/null | \
                 grep "events per second" | awk '{print $4}')
        [[ -n "$result" && "$result" =~ ^[0-9.]+$ ]] && results+=("$result")
    done
    echo ""
    
    if [[ ${#results[@]} -gt 0 ]]; then
        CPU_SINGLE_RAW=$(array_mean "${results[@]}")
        local stddev=$(array_stddev "${results[@]}")
        CPU_SINGLE_SCORE=$(calc "$CPU_SINGLE_RAW * 100 / $REF_CPU_SINGLE")
        
        print_metric "Events/sec" "$(printf "%.1f" "$CPU_SINGLE_RAW")" "ops/s" "$CPU_SINGLE_SCORE"
        print_metric "Std Deviation" "$(printf "%.1f" "$stddev")" "σ"
    else
        log_warn "Test failed"
        CPU_SINGLE_SCORE=50
    fi
    
    # Test 2: Multi-thread
    echo -e "\n  ${C_BOLD}Test 2: Multi-Thread Integer Performance (${threads} threads)${C_RESET}"
    log_info "Computing prime numbers (multi-threaded)..."
    
    results=()
    
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        sysbench cpu --cpu-max-prime=20000 --threads=$threads run &>/dev/null
    done
    
    for ((i=1; i<=TEST_ITERATIONS; i++)); do
        print_progress $i $TEST_ITERATIONS "Iteration"
        local result
        result=$(sysbench cpu --cpu-max-prime=20000 --threads=$threads run 2>/dev/null | \
                 grep "events per second" | awk '{print $4}')
        [[ -n "$result" && "$result" =~ ^[0-9.]+$ ]] && results+=("$result")
    done
    echo ""
    
    if [[ ${#results[@]} -gt 0 ]]; then
        CPU_MULTI_RAW=$(array_mean "${results[@]}")
        local stddev=$(array_stddev "${results[@]}")
        CPU_MULTI_SCORE=$(calc "$CPU_MULTI_RAW * 100 / $REF_CPU_MULTI")
        
        if [[ $(calc "$CPU_SINGLE_RAW > 0") == "1" ]]; then
            CPU_SCALING=$(calc "($CPU_MULTI_RAW / $CPU_SINGLE_RAW) / $threads * 100")
        fi
        
        print_metric "Events/sec" "$(printf "%.1f" "$CPU_MULTI_RAW")" "ops/s" "$CPU_MULTI_SCORE"
        print_metric "Std Deviation" "$(printf "%.1f" "$stddev")" "σ"
        print_metric "Scaling Efficiency" "$(printf "%.1f" "$CPU_SCALING")" "%"
    else
        log_warn "Test failed"
        CPU_MULTI_SCORE=50
    fi
    
    # Test 3: Compression
    echo -e "\n  ${C_BOLD}Test 3: Compression Performance${C_RESET}"
    log_info "Testing gzip compression throughput..."
    
    dd if=/dev/zero bs=1M count=100 2>/dev/null | tr '\0' 'A' > "$TEMP_DIR/compress_test" 2>/dev/null
    
    if [[ -f "$TEMP_DIR/compress_test" ]]; then
        results=()
        for ((i=1; i<=TEST_ITERATIONS; i++)); do
            print_progress $i $TEST_ITERATIONS "Iteration"
            local start end duration throughput
            start=$(date +%s.%N)
            gzip -c -1 "$TEMP_DIR/compress_test" > /dev/null 2>&1
            end=$(date +%s.%N)
            duration=$(calc "$end - $start")
            if [[ $(calc "$duration > 0.01") == "1" ]]; then
                throughput=$(calc "102400 / $duration")
                results+=("$throughput")
            fi
        done
        echo ""
        
        if [[ ${#results[@]} -gt 0 ]]; then
            CPU_COMPRESS_RAW=$(array_mean "${results[@]}")
            CPU_COMPRESS_SCORE=$(calc "$CPU_COMPRESS_RAW * 100 / $REF_CPU_COMPRESS")
            print_metric "Throughput" "$(printf "%.0f" "$CPU_COMPRESS_RAW")" "KB/s" "$CPU_COMPRESS_SCORE"
        fi
        
        rm -f "$TEMP_DIR/compress_test"
    fi
    
    # Aggregate
    local total=0 count=0
    for score in $CPU_SINGLE_SCORE $CPU_MULTI_SCORE $CPU_COMPRESS_SCORE; do
        if [[ $(calc "$score > 0") == "1" ]]; then
            total=$(calc "$total + $score")
            ((count++))
        fi
    done
    
    [[ $count -gt 0 ]] && CPU_AGGREGATE=$(calc "$total / $count") || CPU_AGGREGATE=50
    
    echo ""
    echo -e "  ${C_BOLD}CPU Aggregate Score: ${C_GREEN}$(printf "%.1f" "$CPU_AGGREGATE")${C_RESET}/100"
}

# ============================================================================
# MEMORY BENCHMARKS
# ============================================================================

MEM_BANDWIDTH_SCORE=0
MEM_AGGREGATE=0
MEM_BANDWIDTH_RAW=0

benchmark_memory() {
    print_header "Memory Benchmark Suite"
    
    echo -e "\n  ${C_BOLD}Test 1: Memory Bandwidth (Sequential)${C_RESET}"
    log_info "Measuring memory throughput..."
    
    local results=()
    
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        sysbench memory --memory-block-size=1M --memory-total-size=2G --threads=4 run &>/dev/null
    done
    
    for ((i=1; i<=TEST_ITERATIONS; i++)); do
        print_progress $i $TEST_ITERATIONS "Iteration"
        local output result
        output=$(sysbench memory --memory-block-size=1M --memory-total-size=4G --threads=4 run 2>/dev/null)
        result=$(echo "$output" | grep -oP '[\d.]+(?=\s*MiB/sec)' | head -1)
        if [[ -z "$result" ]]; then
            result=$(echo "$output" | grep "transferred" | grep -oP '[\d.]+' | tail -1)
        fi
        [[ -n "$result" && "$result" =~ ^[0-9.]+$ ]] && results+=("$result")
    done
    echo ""
    
    if [[ ${#results[@]} -gt 0 ]]; then
        MEM_BANDWIDTH_RAW=$(array_mean "${results[@]}")
        local stddev=$(array_stddev "${results[@]}")
        MEM_BANDWIDTH_SCORE=$(calc "$MEM_BANDWIDTH_RAW * 100 / $REF_MEM_BANDWIDTH")
        
        print_metric "Bandwidth" "$(printf "%.0f" "$MEM_BANDWIDTH_RAW")" "MiB/s" "$MEM_BANDWIDTH_SCORE"
        print_metric "Std Deviation" "$(printf "%.0f" "$stddev")" "σ"
    else
        log_warn "Test failed"
        MEM_BANDWIDTH_SCORE=50
    fi
    
    # Random access
    echo -e "\n  ${C_BOLD}Test 2: Memory Random Access${C_RESET}"
    log_info "Measuring random access performance..."
    
    results=()
    for ((i=1; i<=TEST_ITERATIONS; i++)); do
        print_progress $i $TEST_ITERATIONS "Iteration"
        local output result
        output=$(sysbench memory --memory-block-size=4K --memory-total-size=1G \
                 --memory-access-mode=rnd --threads=1 run 2>/dev/null)
        result=$(echo "$output" | grep -oP '[\d.]+(?=\s*MiB/sec)' | head -1)
        [[ -z "$result" ]] && result=$(echo "$output" | grep "transferred" | grep -oP '[\d.]+' | tail -1)
        [[ -n "$result" && "$result" =~ ^[0-9.]+$ ]] && results+=("$result")
    done
    echo ""
    
    if [[ ${#results[@]} -gt 0 ]]; then
        local random_mean=$(array_mean "${results[@]}")
        print_metric "Random Access" "$(printf "%.0f" "$random_mean")" "MiB/s"
    fi
    
    MEM_AGGREGATE=$MEM_BANDWIDTH_SCORE
    
    echo ""
    echo -e "  ${C_BOLD}Memory Aggregate Score: ${C_GREEN}$(printf "%.1f" "$MEM_AGGREGATE")${C_RESET}/100"
}

# ============================================================================
# STORAGE BENCHMARKS
# ============================================================================

DISK_SEQ_READ_SCORE=0
DISK_SEQ_WRITE_SCORE=0
DISK_RAND_READ_SCORE=0
DISK_RAND_WRITE_SCORE=0
DISK_AGGREGATE=0
DISK_SEQ_READ_RAW=0
DISK_SEQ_WRITE_RAW=0
DISK_RAND_READ_RAW=0
DISK_RAND_WRITE_RAW=0
DISK_MIXED_RAW=0

benchmark_storage() {
    print_header "Storage Benchmark Suite"
    
    local test_dir="$TEMP_DIR/fio_test"
    mkdir -p "$test_dir"
    
    # Use direct I/O to bypass cache (critical for HDD)
    local direct_flag="--direct=1"
    if [[ "$SYS_DISK_TYPE" == "HDD" ]]; then
        log_info "HDD detected - using direct I/O (bypassing cache)"
    fi
    
    # Test 1: Sequential Read
    echo -e "\n  ${C_BOLD}Test 1: Sequential Read${C_RESET}"
    log_info "Testing sequential read throughput..."
    
    fio --name=precreate --filename="$test_dir/testfile" --size=512M --rw=write --bs=1M $direct_flag &>/dev/null
    
    local output bw
    output=$(fio --name=seq_read --filename="$test_dir/testfile" --rw=read --bs=1M --size=512M \
                 --numjobs=1 --runtime=15 --time_based $direct_flag \
                 --output-format=json 2>/dev/null)
    
    if command -v jq &>/dev/null; then
        bw=$(echo "$output" | jq -r '.jobs[0].read.bw_bytes // 0' 2>/dev/null)
    else
        bw=$(echo "$output" | grep -oP '"bw_bytes"\s*:\s*\K[0-9]+' | head -1)
    fi
    bw=${bw:-0}
    
    if [[ "$bw" -gt 0 ]]; then
        DISK_SEQ_READ_RAW=$(calc "$bw / 1048576")
        DISK_SEQ_READ_SCORE=$(calc "$DISK_SEQ_READ_RAW * 100 / $REF_DISK_SEQ_READ")
        print_metric "Sequential Read" "$(printf "%.0f" "$DISK_SEQ_READ_RAW")" "MB/s" "$DISK_SEQ_READ_SCORE"
    else
        DISK_SEQ_READ_SCORE=50
        log_warn "Test failed"
    fi
    
    # Test 2: Sequential Write
    echo -e "\n  ${C_BOLD}Test 2: Sequential Write${C_RESET}"
    log_info "Testing sequential write throughput..."
    
    rm -f "$test_dir"/* 2>/dev/null
    output=$(fio --name=seq_write --directory="$test_dir" --rw=write --bs=1M --size=512M \
                 --numjobs=1 --runtime=15 --time_based $direct_flag \
                 --output-format=json 2>/dev/null)
    
    if command -v jq &>/dev/null; then
        bw=$(echo "$output" | jq -r '.jobs[0].write.bw_bytes // 0' 2>/dev/null)
    else
        bw=$(echo "$output" | grep -oP '"bw_bytes"\s*:\s*\K[0-9]+' | head -1)
    fi
    bw=${bw:-0}
    
    if [[ "$bw" -gt 0 ]]; then
        DISK_SEQ_WRITE_RAW=$(calc "$bw / 1048576")
        DISK_SEQ_WRITE_SCORE=$(calc "$DISK_SEQ_WRITE_RAW * 100 / $REF_DISK_SEQ_WRITE")
        print_metric "Sequential Write" "$(printf "%.0f" "$DISK_SEQ_WRITE_RAW")" "MB/s" "$DISK_SEQ_WRITE_SCORE"
    else
        DISK_SEQ_WRITE_SCORE=50
        log_warn "Test failed"
    fi
    
    # Test 3: Random Read IOPS
    echo -e "\n  ${C_BOLD}Test 3: Random Read IOPS (4K)${C_RESET}"
    log_info "Testing random read performance..."
    
    rm -f "$test_dir"/* 2>/dev/null
    output=$(fio --name=rand_read --directory="$test_dir" --rw=randread --bs=4K --size=256M \
                 --numjobs=4 --runtime=15 --time_based $direct_flag \
                 --output-format=json 2>/dev/null)
    
    local iops
    if command -v jq &>/dev/null; then
        iops=$(echo "$output" | jq -r '.jobs[0].read.iops // 0' 2>/dev/null)
    else
        iops=$(echo "$output" | grep -oP '"iops"\s*:\s*\K[0-9.]+' | head -1)
    fi
    iops=${iops%%.*}
    iops=${iops:-0}
    
    if [[ "$iops" -gt 0 ]]; then
        DISK_RAND_READ_RAW=$iops
        DISK_RAND_READ_SCORE=$(calc "$DISK_RAND_READ_RAW * 100 / $REF_DISK_RAND_READ")
        print_metric "Random Read" "$DISK_RAND_READ_RAW" "IOPS" "$DISK_RAND_READ_SCORE"
    else
        DISK_RAND_READ_SCORE=50
        log_warn "Test failed"
    fi
    
    # Test 4: Random Write IOPS
    echo -e "\n  ${C_BOLD}Test 4: Random Write IOPS (4K)${C_RESET}"
    log_info "Testing random write performance..."
    
    rm -f "$test_dir"/* 2>/dev/null
    output=$(fio --name=rand_write --directory="$test_dir" --rw=randwrite --bs=4K --size=256M \
                 --numjobs=4 --runtime=15 --time_based $direct_flag \
                 --output-format=json 2>/dev/null)
    
    if command -v jq &>/dev/null; then
        iops=$(echo "$output" | jq -r '.jobs[0].write.iops // 0' 2>/dev/null)
    else
        iops=$(echo "$output" | grep -oP '"iops"\s*:\s*\K[0-9.]+' | head -1)
    fi
    iops=${iops%%.*}
    iops=${iops:-0}
    
    if [[ "$iops" -gt 0 ]]; then
        DISK_RAND_WRITE_RAW=$iops
        DISK_RAND_WRITE_SCORE=$(calc "$DISK_RAND_WRITE_RAW * 100 / $REF_DISK_RAND_WRITE")
        print_metric "Random Write" "$DISK_RAND_WRITE_RAW" "IOPS" "$DISK_RAND_WRITE_SCORE"
    else
        DISK_RAND_WRITE_SCORE=50
        log_warn "Test failed"
    fi
    
    # Test 5: Mixed
    echo -e "\n  ${C_BOLD}Test 5: Mixed Random I/O (70/30)${C_RESET}"
    log_info "Testing mixed workload..."
    
    rm -f "$test_dir"/* 2>/dev/null
    output=$(fio --name=mixed --directory="$test_dir" --rw=randrw --rwmixread=70 --bs=4K --size=256M \
                 --numjobs=4 --runtime=15 --time_based $direct_flag \
                 --output-format=json 2>/dev/null)
    
    local read_iops write_iops
    if command -v jq &>/dev/null; then
        read_iops=$(echo "$output" | jq -r '.jobs[0].read.iops // 0' 2>/dev/null)
        write_iops=$(echo "$output" | jq -r '.jobs[0].write.iops // 0' 2>/dev/null)
    else
        read_iops=0
        write_iops=0
    fi
    read_iops=${read_iops%%.*}
    write_iops=${write_iops%%.*}
    DISK_MIXED_RAW=$((${read_iops:-0} + ${write_iops:-0}))
    
    [[ $DISK_MIXED_RAW -gt 0 ]] && print_metric "Mixed IOPS" "$DISK_MIXED_RAW" "IOPS"
    
    rm -rf "$test_dir" 2>/dev/null
    
    # Aggregate
    local total=0 count=0
    for score in $DISK_SEQ_READ_SCORE $DISK_SEQ_WRITE_SCORE $DISK_RAND_READ_SCORE $DISK_RAND_WRITE_SCORE; do
        if [[ $(calc "$score > 0") == "1" ]]; then
            total=$(calc "$total + $score")
            ((count++))
        fi
    done
    
    [[ $count -gt 0 ]] && DISK_AGGREGATE=$(calc "$total / $count") || DISK_AGGREGATE=50
    
    echo ""
    echo -e "  ${C_BOLD}Storage Aggregate Score: ${C_GREEN}$(printf "%.1f" "$DISK_AGGREGATE")${C_RESET}/100"
}

# ============================================================================
# FINAL RESULTS
# ============================================================================

FINAL_SCORE=0
FINAL_GRADE=""
FINAL_CATEGORY=""

calculate_final_score() {
    print_header "Final Results"
    
    local cpu_weight=0.40
    local mem_weight=0.25
    local disk_weight=0.35
    
    local cpu_score=${CPU_AGGREGATE:-50}
    local mem_score=${MEM_AGGREGATE:-50}
    local disk_score=${DISK_AGGREGATE:-50}
    
    FINAL_SCORE=$(calc "($cpu_score * $cpu_weight) + ($mem_score * $mem_weight) + ($disk_score * $disk_weight)")
    
    local score_int=${FINAL_SCORE%%.*}
    score_int=${score_int:-50}
    
    if [[ $score_int -ge 150 ]]; then
        FINAL_GRADE="S" FINAL_CATEGORY="Exceptional"
    elif [[ $score_int -ge 120 ]]; then
        FINAL_GRADE="A" FINAL_CATEGORY="Excellent"
    elif [[ $score_int -ge 100 ]]; then
        FINAL_GRADE="B" FINAL_CATEGORY="Very Good"
    elif [[ $score_int -ge 80 ]]; then
        FINAL_GRADE="C" FINAL_CATEGORY="Good"
    elif [[ $score_int -ge 60 ]]; then
        FINAL_GRADE="D" FINAL_CATEGORY="Average"
    else
        FINAL_GRADE="F" FINAL_CATEGORY="Below Average"
    fi
    
    echo ""
    echo -e "  ${C_BOLD}Component Scores${C_RESET}"
    echo -e "  ─────────────────────────────────────────────────"
    printf "  %-20s %8.1f / 100  (weight: %.0f%%)\n" "CPU" "$cpu_score" "$(calc "$cpu_weight * 100")"
    printf "  %-20s %8.1f / 100  (weight: %.0f%%)\n" "Memory" "$mem_score" "$(calc "$mem_weight * 100")"
    printf "  %-20s %8.1f / 100  (weight: %.0f%%)\n" "Storage" "$disk_score" "$(calc "$disk_weight * 100")"
    echo -e "  ─────────────────────────────────────────────────"
    
    local color=$C_GREEN
    [[ $score_int -lt 80 ]] && color=$C_YELLOW
    [[ $score_int -lt 60 ]] && color=$C_RED
    
    echo ""
    echo -e "  ${C_BOLD}╔═══════════════════════════════════════════════╗${C_RESET}"
    echo -e "  ${C_BOLD}║           SYSTEMBENCH PRO SCORE               ║${C_RESET}"
    echo -e "  ${C_BOLD}╠═══════════════════════════════════════════════╣${C_RESET}"
    printf "  ${C_BOLD}║${C_RESET}              ${color}${C_BOLD}%6.1f${C_RESET} / 100                  ${C_BOLD}║${C_RESET}\n" "$FINAL_SCORE"
    printf "  ${C_BOLD}║${C_RESET}           Grade: ${color}${C_BOLD}%s${C_RESET} - %-15s       ${C_BOLD}║${C_RESET}\n" "$FINAL_GRADE" "$FINAL_CATEGORY"
    echo -e "  ${C_BOLD}╚═══════════════════════════════════════════════╝${C_RESET}"
    
    echo ""
    echo -e "  ${C_DIM}Reference: Intel i5-10400, 16GB DDR4-2666, SATA SSD = 100${C_RESET}"
}

# ============================================================================
# EXPORT
# ============================================================================

export_json() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local filename="$RESULTS_DIR/benchmark_$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$filename" << EOF
{
    "metadata": {
        "version": "$VERSION",
        "timestamp": "$timestamp",
        "hostname": "$SYS_HOSTNAME"
    },
    "system": {
        "cpu": {
            "model": "$SYS_CPU_MODEL",
            "cores": $SYS_CPU_CORES,
            "threads": $SYS_CPU_THREADS,
            "architecture": "$SYS_CPU_ARCH"
        },
        "memory": {
            "total_gb": $SYS_MEM_TOTAL_GB,
            "type": "$SYS_MEM_TYPE",
            "speed": "$SYS_MEM_SPEED"
        },
        "storage": {
            "model": "$SYS_DISK_MODEL",
            "size": "$SYS_DISK_SIZE",
            "type": "$SYS_DISK_TYPE"
        },
        "os": {
            "name": "$SYS_OS_NAME",
            "kernel": "$SYS_KERNEL"
        }
    },
    "results": {
        "cpu": {
            "single_thread": $CPU_SINGLE_RAW,
            "multi_thread": $CPU_MULTI_RAW,
            "compression_kbps": $CPU_COMPRESS_RAW,
            "scaling_efficiency": $CPU_SCALING,
            "score": $CPU_AGGREGATE
        },
        "memory": {
            "bandwidth_mbps": $MEM_BANDWIDTH_RAW,
            "score": $MEM_AGGREGATE
        },
        "storage": {
            "seq_read_mbps": $DISK_SEQ_READ_RAW,
            "seq_write_mbps": $DISK_SEQ_WRITE_RAW,
            "rand_read_iops": $DISK_RAND_READ_RAW,
            "rand_write_iops": $DISK_RAND_WRITE_RAW,
            "mixed_iops": $DISK_MIXED_RAW,
            "score": $DISK_AGGREGATE
        },
        "final": {
            "score": $FINAL_SCORE,
            "grade": "$FINAL_GRADE",
            "category": "$FINAL_CATEGORY"
        }
    }
}
EOF
    
    log_success "JSON saved: $filename"
    echo "$filename"
}

generate_html_report() {
    local json_file="$1"
    local html_file="$REPORTS_DIR/report_$(date +%Y%m%d_%H%M%S).html"
    local json_content
    json_content=$(cat "$json_file")
    
    cat > "$html_file" << 'HTMLHEADER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SystemBench Pro Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root { --bg:#0d1117; --bg2:#161b22; --fg:#f0f6fc; --fg2:#8b949e; --blue:#58a6ff; --green:#3fb950; --yellow:#d29922; --red:#f85149; --border:#30363d; }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif; background:var(--bg); color:var(--fg); line-height:1.6; padding:2rem; }
        .container { max-width:1200px; margin:0 auto; }
        header { text-align:center; padding:2rem 0; border-bottom:1px solid var(--border); margin-bottom:2rem; }
        h1 { font-size:2.5rem; background:linear-gradient(135deg,var(--blue),var(--green)); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
        .subtitle { color:var(--fg2); }
        .score-hero { background:var(--bg2); border:1px solid var(--border); border-radius:12px; padding:3rem; text-align:center; margin-bottom:2rem; }
        .score-value { font-size:5rem; font-weight:700; }
        .score-grade { display:inline-block; font-size:1.5rem; font-weight:600; padding:0.5rem 1.5rem; border-radius:8px; margin-top:1rem; }
        .grade-s,.grade-a { background:var(--green); color:var(--bg); }
        .grade-b,.grade-c { background:var(--blue); color:var(--bg); }
        .grade-d { background:var(--yellow); color:var(--bg); }
        .grade-f { background:var(--red); color:var(--bg); }
        .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:1.5rem; margin-bottom:2rem; }
        .card { background:var(--bg2); border:1px solid var(--border); border-radius:12px; padding:1.5rem; }
        .card h2 { font-size:1.1rem; margin-bottom:1rem; }
        .metric { display:flex; justify-content:space-between; padding:0.5rem 0; border-bottom:1px solid var(--border); }
        .metric:last-child { border-bottom:none; }
        .metric-label { color:var(--fg2); }
        .metric-value { font-weight:600; font-family:monospace; }
        .chart-container { height:250px; }
        footer { text-align:center; padding:2rem 0; color:var(--fg2); border-top:1px solid var(--border); margin-top:2rem; }
    </style>
</head>
<body>
<div class="container">
    <header><h1>SystemBench Pro</h1><p class="subtitle">Performance Report</p><p class="subtitle" id="ts"></p></header>
    <div class="score-hero">
        <div class="score-value" id="score">--</div><div>/100</div>
        <div class="score-grade" id="grade">--</div>
        <p style="color:var(--fg2);margin-top:1rem" id="cat"></p>
    </div>
    <div class="grid">
        <div class="card"><h2>📊 Scores</h2><div class="chart-container"><canvas id="chart"></canvas></div></div>
        <div class="card"><h2>⚡ CPU</h2>
            <div class="metric"><span class="metric-label">Single-Thread</span><span class="metric-value" id="cpu1">--</span></div>
            <div class="metric"><span class="metric-label">Multi-Thread</span><span class="metric-value" id="cpu2">--</span></div>
            <div class="metric"><span class="metric-label">Score</span><span class="metric-value" id="cpus">--</span></div>
        </div>
        <div class="card"><h2>💎 Memory</h2>
            <div class="metric"><span class="metric-label">Bandwidth</span><span class="metric-value" id="mem1">--</span></div>
            <div class="metric"><span class="metric-label">Score</span><span class="metric-value" id="mems">--</span></div>
        </div>
        <div class="card"><h2>💿 Storage</h2>
            <div class="metric"><span class="metric-label">Seq Read</span><span class="metric-value" id="d1">--</span></div>
            <div class="metric"><span class="metric-label">Seq Write</span><span class="metric-value" id="d2">--</span></div>
            <div class="metric"><span class="metric-label">Random IOPS</span><span class="metric-value" id="d3">--</span></div>
            <div class="metric"><span class="metric-label">Score</span><span class="metric-value" id="ds">--</span></div>
        </div>
    </div>
    <div class="card"><h2>🖥️ System</h2>
        <div class="grid" style="grid-template-columns:repeat(auto-fit,minmax(200px,1fr))">
            <div class="metric"><span class="metric-label">CPU</span><span class="metric-value" id="scpu">--</span></div>
            <div class="metric"><span class="metric-label">RAM</span><span class="metric-value" id="sram">--</span></div>
            <div class="metric"><span class="metric-label">Disk</span><span class="metric-value" id="sdisk">--</span></div>
            <div class="metric"><span class="metric-label">OS</span><span class="metric-value" id="sos">--</span></div>
        </div>
    </div>
    <footer><p>SystemBench Pro v1.2</p><p>Reference: i5-10400 + 16GB DDR4 + SATA SSD = 100</p></footer>
</div>
<script>
HTMLHEADER

    echo "const d=$json_content;" >> "$html_file"
    
    cat >> "$html_file" << 'HTMLFOOTER'
document.getElementById('ts').textContent=new Date(d.metadata.timestamp).toLocaleString();
document.getElementById('score').textContent=d.results.final.score.toFixed(1);
document.getElementById('cat').textContent=d.results.final.category;
const gb=document.getElementById('grade');
gb.textContent='Grade '+d.results.final.grade;
gb.className='score-grade grade-'+d.results.final.grade.toLowerCase();
document.getElementById('cpu1').textContent=d.results.cpu.single_thread.toFixed(0)+' ops/s';
document.getElementById('cpu2').textContent=d.results.cpu.multi_thread.toFixed(0)+' ops/s';
document.getElementById('cpus').textContent=d.results.cpu.score.toFixed(1)+'/100';
document.getElementById('mem1').textContent=d.results.memory.bandwidth_mbps.toFixed(0)+' MiB/s';
document.getElementById('mems').textContent=d.results.memory.score.toFixed(1)+'/100';
document.getElementById('d1').textContent=d.results.storage.seq_read_mbps.toFixed(0)+' MB/s';
document.getElementById('d2').textContent=d.results.storage.seq_write_mbps.toFixed(0)+' MB/s';
document.getElementById('d3').textContent=d.results.storage.rand_read_iops+' IOPS';
document.getElementById('ds').textContent=d.results.storage.score.toFixed(1)+'/100';
document.getElementById('scpu').textContent=d.system.cpu.model.substring(0,30);
document.getElementById('sram').textContent=d.system.memory.total_gb.toFixed(1)+' GB';
document.getElementById('sdisk').textContent=d.system.storage.type+' '+d.system.storage.size;
document.getElementById('sos').textContent=d.system.os.name.substring(0,25);
new Chart(document.getElementById('chart'),{type:'radar',data:{labels:['CPU','Memory','Storage'],datasets:[{label:'Score',data:[d.results.cpu.score,d.results.memory.score,d.results.storage.score],backgroundColor:'rgba(88,166,255,0.2)',borderColor:'#58a6ff',pointBackgroundColor:'#58a6ff'},{label:'Reference',data:[100,100,100],backgroundColor:'rgba(139,148,158,0.1)',borderColor:'rgba(139,148,158,0.5)',borderDash:[5,5],pointRadius:0}]},options:{responsive:true,maintainAspectRatio:false,scales:{r:{beginAtZero:true,max:150,ticks:{color:'#8b949e'},grid:{color:'#30363d'},pointLabels:{color:'#f0f6fc'}}},plugins:{legend:{labels:{color:'#8b949e'}}}}});
</script>
</body>
</html>
HTMLFOOTER
    
    log_success "HTML saved: $html_file"
}

# ============================================================================
# MAIN
# ============================================================================

show_banner() {
    echo -e "${C_CYAN}${C_BOLD}"
    cat << 'EOF'
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗                    ║
  ║   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║                    ║
  ║   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║                    ║
  ║   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║                    ║
  ║   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║                    ║
  ║   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝                    ║
  ║   ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗    ██████╗ ██████╗  ██████╗   ║
  ║   ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║    ██╔══██╗██╔══██╗██╔═══██╗  ║
  ║   ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║    ██████╔╝██████╔╝██║   ██║  ║
  ║   ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║    ██╔═══╝ ██╔══██╗██║   ██║  ║
  ║   ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║    ██║     ██║  ██║╚██████╔╝  ║
  ║   ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ║
  ║              Professional System Performance Analysis v1.2                ║
  ╚════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help          Show help
    -q, --quick         Quick mode (2 iterations)
    --cpu-only          CPU tests only
    --mem-only          Memory tests only
    --disk-only         Storage tests only
    --no-report         Skip HTML report
EOF
}

main() {
    local run_cpu=true run_mem=true run_disk=true gen_report=true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_usage; exit 0 ;;
            -q|--quick) WARMUP_ITERATIONS=1; TEST_ITERATIONS=2 ;;
            --cpu-only) run_mem=false; run_disk=false ;;
            --mem-only) run_cpu=false; run_disk=false ;;
            --disk-only) run_cpu=false; run_mem=false ;;
            --no-report) gen_report=false ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
    
    show_banner
    
    echo -e "  ${C_DIM}Estimated duration: 5-10 minutes${C_RESET}"
    echo -e "  ${C_DIM}Close other applications for best results${C_RESET}"
    echo ""
    read -p "  Press ENTER to start..." -r
    
    init_directories
    check_dependencies || exit 1
    
    local start_time=$(date +%s)
    
    collect_system_info
    check_system_state
    
    [[ "$run_cpu" == true ]] && benchmark_cpu
    [[ "$run_mem" == true ]] && benchmark_memory
    [[ "$run_disk" == true ]] && benchmark_storage
    
    calculate_final_score
    
    print_header "Export Results"
    
    local json_file
    json_file=$(export_json)
    
    [[ "$gen_report" == true ]] && generate_html_report "$json_file"
    
    local duration=$(($(date +%s) - start_time))
    echo ""
    log_success "Completed in ${duration}s"
}

main "$@"