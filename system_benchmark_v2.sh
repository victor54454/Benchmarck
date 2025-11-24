#!/bin/bash

# ============================================
# SYSTEM BENCHMARK TOOL v2.0 - Beautiful Edition
# Tests complets de performance système
# ============================================

set -e

# Couleurs et styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Caractères spéciaux
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"
ROCKET="🚀"
FIRE="🔥"
TROPHY="🏆"
SPARKLE="✨"
GEAR="⚙"
CHART="📊"

# Variables globales
CPU_SCORE=0
RAM_SCORE=0
DISK_SCORE=0
GPU_SCORE=0
FINAL_SCORE=0

# Obtenir le dossier du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}.txt"

mkdir -p "$RESULTS_DIR"

# ============================================
# FONCTIONS D'AFFICHAGE AMÉLIORÉES
# ============================================

clear_line() {
    echo -ne "\033[2K\r"
}

progress_bar() {
    local progress=$1
    local total=50
    local filled=$((progress * total / 100))
    local empty=$((total - filled))
    
    local color=$RED
    if [ $progress -gt 33 ]; then color=$YELLOW; fi
    if [ $progress -gt 66 ]; then color=$GREEN; fi
    
    printf "\r${color}${BOLD}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} ${WHITE}${BOLD}%3d%%${NC}" $progress
}

animated_title() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██████╗   ║
    ║   ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗██╔══██╗  ║
    ║   ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║██████╔╝  ║
    ║   ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔══██╗  ║
    ║   ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║  ║
    ║   ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ║
    ║                                                                       ║
    ║              Professional System Performance Analysis                 ║
    ║                           version 2.0                                 ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "\n${CYAN}${BOLD}${GEAR} Initialisation du système de benchmark...${NC}\n"
    for i in {1..3}; do
        progress_bar $((i * 33))
        sleep 0.3
    done
    progress_bar 100
    echo -e "\n"
    sleep 0.5
}

section_header() {
    local title=$1
    local icon=$2
    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${icon} ${WHITE}${BOLD}${title}${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}${BOLD}[${ARROW}]${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}${BOLD}[${CHECK}]${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[!]${NC} ${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}${BOLD}[${CROSS}]${NC} ${RED}$1${NC}"
}

display_score() {
    local label=$1
    local score=$2
    local max=$3
    local icon=$4
    
    local percentage=$((score * 100 / max))
    local color=$RED
    if [ $percentage -gt 40 ]; then color=$YELLOW; fi
    if [ $percentage -gt 70 ]; then color=$GREEN; fi
    
    echo -e "${icon} ${WHITE}${BOLD}${label}:${NC} ${color}${BOLD}${score}${NC}/${max}"
    
    local bar_length=30
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))
    
    printf "   ${color}["
    printf "%${filled}s" | tr ' ' '▰'
    printf "%${empty}s" | tr ' ' '▱'
    printf "]${NC} ${DIM}%d%%${NC}\n\n" $percentage
}

check_dependencies() {
    section_header "Vérification des Dépendances" "🔍"
    
    local deps=("sysbench" "fio" "glxinfo" "bc" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if command -v $dep &> /dev/null; then
            printf "${GREEN}${CHECK}${NC} %-15s ${DIM}[installé]${NC}\n" "$dep"
        else
            printf "${RED}${CROSS}${NC} %-15s ${DIM}[manquant]${NC}\n" "$dep"
            missing+=($dep)
        fi
        sleep 0.1
    done
    
    echo ""
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Dépendances manquantes: ${missing[*]}"
        echo ""
        echo -e "${YELLOW}${BOLD}Installation requise:${NC}"
        echo -e "  ${WHITE}Ubuntu/Debian:${NC} sudo apt install sysbench fio mesa-utils bc jq"
        echo -e "  ${WHITE}Fedora/RHEL:${NC}   sudo dnf install sysbench fio mesa-demos bc jq"
        echo -e "  ${WHITE}Arch:${NC}          sudo pacman -S sysbench fio mesa-utils bc jq"
        echo ""
        exit 1
    fi
    
    print_success "Toutes les dépendances sont installées !"
    sleep 1
}

get_system_info() {
    section_header "Informations Système" "💻"
    
    echo "=== SYSTEM INFO ===" >> "$RESULTS_FILE"
    
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    CPU_CORES=$(nproc)
    CPU_THREADS=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}Hostname:${NC}     $(hostname)"
    echo -e "${CYAN}│${NC} ${BOLD}OS:${NC}           $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${CYAN}│${NC} ${BOLD}Kernel:${NC}       $(uname -r)"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}🖥️  PROCESSEUR${NC}"
    echo -e "${CYAN}│${NC}     ${CPU_MODEL}"
    echo -e "${CYAN}│${NC}     ${GREEN}${CPU_CORES}${NC} cores / ${GREEN}${CPU_THREADS}${NC} threads"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}💾  MÉMOIRE${NC}"
    echo -e "${CYAN}│${NC}     ${GREEN}${RAM_TOTAL}${NC} RAM"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    
    if command -v lspci &> /dev/null; then
        GPU_INFO=$(lspci | grep -i "vga\|3d\|display" | cut -d':' -f3 | xargs | head -1)
        echo -e "${CYAN}│${NC} ${WHITE}${BOLD}🎮  GPU${NC}"
        echo -e "${CYAN}│${NC}     ${GPU_INFO}"
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    
    {
        echo "CPU: $CPU_MODEL ($CPU_CORES cores / $CPU_THREADS threads)"
        echo "RAM: $RAM_TOTAL"
        echo "GPU: $GPU_INFO"
        echo ""
    } >> "$RESULTS_FILE"
    
    sleep 2
}

test_cpu() {
    section_header "TEST CPU - Puissance de Calcul" "🖥️"
    
    echo "=== CPU BENCHMARK ===" >> "$RESULTS_FILE"
    
    print_info "Test single-thread en cours..."
    echo ""
    
    (sysbench cpu --cpu-max-prime=20000 --threads=1 run > /tmp/cpu_single.txt 2>&1) &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.03
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local single_result=$(grep "events per second" /tmp/cpu_single.txt | awk '{print $4}')
    echo -e "${WHITE}Single-thread:${NC} ${GREEN}${BOLD}${single_result}${NC} events/sec"
    echo ""
    
    print_info "Test multi-thread avec ${CPU_THREADS} threads..."
    echo ""
    
    (sysbench cpu --cpu-max-prime=20000 --threads=$CPU_THREADS run > /tmp/cpu_multi.txt 2>&1) &
    pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.03
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local multi_result=$(grep "events per second" /tmp/cpu_multi.txt | awk '{print $4}')
    echo -e "${WHITE}Multi-thread:${NC}  ${GREEN}${BOLD}${multi_result}${NC} events/sec"
    echo ""
    
    local single_score=$(echo "scale=2; ($single_result / 2000) * 50" | bc)
    local multi_score=$(echo "scale=2; ($multi_result / 16000) * 50" | bc)
    CPU_SCORE=$(echo "scale=2; $single_score + $multi_score" | bc)
    CPU_SCORE=$(echo "if ($CPU_SCORE > 100) 100 else $CPU_SCORE" | bc)
    
    display_score "Score CPU" "${CPU_SCORE%.*}" "100" "🖥️"
    
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
    section_header "TEST RAM - Vitesse Mémoire" "💾"
    
    echo "=== RAM BENCHMARK ===" >> "$RESULTS_FILE"
    
    print_info "Test de bande passante mémoire..."
    echo ""
    
    (sysbench memory --memory-block-size=1M --memory-total-size=10G --threads=4 run > /tmp/ram_test.txt 2>&1) &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.05
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local mem_write=$(grep "MiB/sec" /tmp/ram_test.txt | tail -1 | awk '{print $2}')
    echo -e "${WHITE}Vitesse:${NC} ${GREEN}${BOLD}${mem_write}${NC} MiB/sec"
    echo ""
    
    RAM_SCORE=$(echo "scale=2; ($mem_write / 10000) * 100" | bc)
    RAM_SCORE=$(echo "if ($RAM_SCORE > 100) 100 else $RAM_SCORE" | bc)
    
    display_score "Score RAM" "${RAM_SCORE%.*}" "100" "💾"
    
    {
        echo "Vitesse: $mem_write MiB/sec"
        echo "RAM: ${RAM_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    rm -f /tmp/ram_test.txt
    sleep 1
}

test_disk() {
    section_header "TEST DISQUE - Performance I/O" "💿"
    
    echo "=== DISK BENCHMARK ===" >> "$RESULTS_FILE"
    
    local test_dir="$SCRIPT_DIR/benchmark_disk_test"
    mkdir -p "$test_dir"
    
    print_warning "Création de fichiers temporaires (~2GB)"
    echo ""
    
    print_info "Test écriture séquentielle..."
    echo ""
    
    (fio --name=seq_write --directory="$test_dir" --rw=write --bs=1M --size=1G --numjobs=1 --runtime=20 --time_based --group_reporting --output-format=json > /tmp/fio_write.json 2>&1) &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.02
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local seq_write=$(jq -r '.jobs[0].write.bw_bytes' /tmp/fio_write.json 2>/dev/null | awk '{printf "%.2f", $1/1048576}')
    echo -e "${WHITE}Écriture:${NC} ${GREEN}${BOLD}${seq_write}${NC} MiB/s"
    echo ""
    
    print_info "Test lecture séquentielle..."
    echo ""
    
    (fio --name=seq_read --directory="$test_dir" --rw=read --bs=1M --size=1G --numjobs=1 --runtime=20 --time_based --group_reporting --output-format=json > /tmp/fio_read.json 2>&1) &
    pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.02
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local seq_read=$(jq -r '.jobs[0].read.bw_bytes' /tmp/fio_read.json 2>/dev/null | awk '{printf "%.2f", $1/1048576}')
    echo -e "${WHITE}Lecture:${NC}  ${GREEN}${BOLD}${seq_read}${NC} MiB/s"
    echo ""
    
    print_info "Test IOPS aléatoires (4K)..."
    echo ""
    
    (fio --name=rand_rw --directory="$test_dir" --rw=randrw --bs=4K --size=512M --numjobs=4 --runtime=15 --time_based --group_reporting --output-format=json > /tmp/fio_rand.json 2>&1) &
    pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        for i in {1..100}; do
            progress_bar $i
            sleep 0.015
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    
    clear_line
    local rand_iops=$(jq -r '.jobs[0].read.iops' /tmp/fio_rand.json 2>/dev/null | awk '{printf "%.0f", $1}')
    echo -e "${WHITE}IOPS:${NC}     ${GREEN}${BOLD}${rand_iops}${NC}"
    echo ""
    
    rm -rf "$test_dir"
    rm -f /tmp/fio_*.json
    
    local seq_score=$(echo "scale=2; ($seq_read / 3000) * 50" | bc)
    local iops_score=$(echo "scale=2; ($rand_iops / 50000) * 50" | bc)
    DISK_SCORE=$(echo "scale=2; $seq_score + $iops_score" | bc)
    DISK_SCORE=$(echo "if ($DISK_SCORE > 100) 100 else $DISK_SCORE" | bc)
    
    display_score "Score Disque" "${DISK_SCORE%.*}" "100" "💿"
    
    {
        echo "Écriture: $seq_write MiB/s"
        echo "Lecture: $seq_read MiB/s"
        echo "IOPS: $rand_iops"
        echo "Disque: ${DISK_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    sleep 1
}

test_gpu() {
    section_header "TEST GPU - Rendu Graphique" "🎮"
    
    echo "=== GPU BENCHMARK ===" >> "$RESULTS_FILE"
    
    if [ -z "$DISPLAY" ] || ! command -v glxgears &> /dev/null; then
        print_warning "Test GPU non disponible"
        GPU_SCORE=50
        echo "GPU: 50.00/100" >> "$RESULTS_FILE"
        echo ""
        sleep 1
        return
    fi
    
    print_info "Test de rendu OpenGL (10 secondes)..."
    echo ""
    
    timeout 11s glxgears 2>&1 > /tmp/glxgears.log &
    local pid=$!
    
    for i in {1..100}; do
        progress_bar $i
        sleep 0.1
    done
    
    kill $pid 2>/dev/null || true
    clear_line
    
    local fps=$(grep "frames in" /tmp/glxgears.log | tail -1 | awk '{print $6}')
    
    if [ -n "$fps" ]; then
        echo -e "${WHITE}FPS OpenGL:${NC} ${GREEN}${BOLD}${fps}${NC}"
        echo ""
        
        GPU_SCORE=$(echo "scale=2; ($fps / 2000) * 100" | bc)
        GPU_SCORE=$(echo "if ($GPU_SCORE > 100) 100 else $GPU_SCORE" | bc)
    else
        print_warning "Impossible de mesurer les FPS"
        GPU_SCORE=50
    fi
    
    display_score "Score GPU" "${GPU_SCORE%.*}" "100" "🎮"
    
    {
        echo "FPS: $fps"
        echo "GPU: ${GPU_SCORE}/100"
        echo ""
    } >> "$RESULTS_FILE"
    
    rm -f /tmp/glxgears.log
    sleep 1
}

calculate_final_score() {
    section_header "Analyse des Résultats" "📊"
    
    print_info "Calcul du score final en cours..."
    echo ""
    for i in {1..100}; do
        progress_bar $i
        sleep 0.02
    done
    clear_line
    echo ""
    
    FINAL_SCORE=$(echo "scale=2; ($CPU_SCORE * 0.35) + ($RAM_SCORE * 0.20) + ($DISK_SCORE * 0.30) + ($GPU_SCORE * 0.15)" | bc)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                    ${WHITE}${BOLD}TABLEAU DES SCORES${NC}                           ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    print_score_line() {
        local icon=$1
        local name=$2
        local score=$3
        local weight=$4
        
        local int_score=${score%.*}
        local color=$RED
        if [ $int_score -gt 40 ]; then color=$YELLOW; fi
        if [ $int_score -gt 70 ]; then color=$GREEN; fi
        
        local bar_length=20
        local filled=$((int_score * bar_length / 100))
        local empty=$((bar_length - filled))
        
        printf "${BOLD}${CYAN}║${NC} ${icon} %-12s ${color}[" "$name"
        printf "%${filled}s" | tr ' ' '▰'
        printf "%${empty}s" | tr ' ' '▱'
        printf "]${NC} ${color}${BOLD}%5.1f${NC}/100 ${DIM}(%s)${NC} ${BOLD}${CYAN}║${NC}\n" "$score" "$weight"
    }
    
    print_score_line "🖥️ " "CPU" "$CPU_SCORE" "35%"
    print_score_line "💾" "RAM" "$RAM_SCORE" "20%"
    print_score_line "💿" "Disque" "$DISK_SCORE" "30%"
    print_score_line "🎮" "GPU" "$GPU_SCORE" "15%"
    
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    local int_final=${FINAL_SCORE%.*}
    local final_color=$RED
    local category=""
    local cat_icon=""
    
    if [ $int_final -ge 80 ]; then
        final_color=$GREEN
        category="EXCELLENT"
        cat_icon="🏆"
    elif [ $int_final -ge 60 ]; then
        final_color=$CYAN
        category="BON"
        cat_icon="✨"
    elif [ $int_final -ge 40 ]; then
        final_color=$YELLOW
        category="MOYEN"
        cat_icon="👍"
    else
        final_color=$RED
        category="FAIBLE"
        cat_icon="⚠️ "
    fi
    
    printf "${BOLD}${CYAN}║${NC}                                                                    ${BOLD}${CYAN}║${NC}\n"
    printf "${BOLD}${CYAN}║${NC}                    ${WHITE}${BOLD}SCORE FINAL${NC}                                ${BOLD}${CYAN}║${NC}\n"
    printf "${BOLD}${CYAN}║${NC}                  ${final_color}${BOLD}%6.2f${NC} / 100                              ${BOLD}${CYAN}║${NC}\n" "$FINAL_SCORE"
    printf "${BOLD}${CYAN}║${NC}                                                                    ${BOLD}${CYAN}║${NC}\n"
    printf "${BOLD}${CYAN}║${NC}              ${cat_icon}  ${final_color}${BOLD}%-10s${NC}                                   ${BOLD}${CYAN}║${NC}\n" "$category"
    
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    if [ $int_final -ge 80 ]; then
        echo -e "        ${GREEN}${BOLD}🔥 PC TRÈS PERFORMANT 🔥${NC}"
        echo -e "        ${DIM}Performance de haut niveau${NC}"
    elif [ $int_final -ge 60 ]; then
        echo -e "        ${CYAN}${BOLD}✨ PC PERFORMANT ✨${NC}"
        echo -e "        ${DIM}Bonnes performances générales${NC}"
    elif [ $int_final -ge 40 ]; then
        echo -e "        ${YELLOW}${BOLD}👍 PC STANDARD 👍${NC}"
        echo -e "        ${DIM}Performances correctes${NC}"
    else
        echo -e "        ${RED}${BOLD}⚠️  PC LIMITÉ ⚠️${NC}"
        echo -e "        ${DIM}Upgrade recommandé${NC}"
    fi
    
    {
        echo "=== SCORES FINAUX ==="
        echo "CPU: ${CPU_SCORE}/100"
        echo "RAM: ${RAM_SCORE}/100"
        echo "Disque: ${DISK_SCORE}/100"
        echo "GPU: ${GPU_SCORE}/100"
        echo "SCORE FINAL: ${FINAL_SCORE}/100"
        echo "Catégorie: $category"
    } >> "$RESULTS_FILE"
    
    sleep 2
}

show_completion() {
    echo ""
    section_header "Benchmark Terminé !" "🎉"
    
    echo -e "${GREEN}${BOLD}${CHECK} Résultats sauvegardés:${NC}"
    echo -e "   ${WHITE}${UNDERLINE}$RESULTS_FILE${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}📊 Prochaines étapes:${NC}"
    echo -e "   ${WHITE}•${NC} Comparer avec d'autres benchmarks: ${YELLOW}./compare_benchmarks_v2.sh${NC}"
    echo -e "   ${WHITE}•${NC} Générer un rapport HTML: ${YELLOW}./generate_html_report_v2.sh${NC}"
    echo -e "   ${WHITE}•${NC} Voir tous les résultats: ${YELLOW}ls -lh ./results/${NC}"
    echo ""
    
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                    ${CYAN}Merci d'avoir utilisé BenchmarkPro${NC}                 "
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

main() {
    animated_title
    
    echo -e "${YELLOW}${BOLD}⏱️  Durée estimée: 5-10 minutes${NC}"
    echo -e "${DIM}Fermez les applications gourmandes pour des résultats optimaux${NC}\n"
    echo -ne "${WHITE}Appuyez sur ${BOLD}[ENTRÉE]${NC}${WHITE} pour démarrer...${NC}"
    read
    
    echo ""
    
    check_dependencies
    get_system_info
    test_cpu
    test_ram
    test_disk
    test_gpu
    calculate_final_score
    show_completion
}

main