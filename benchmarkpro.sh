#!/bin/bash

# ============================================
# BENCHMARKPRO - All-in-One System Benchmark Tool
# Version 2.1 Fixed Edition
# ============================================

set -e

# ============================================
# COULEURS ET STYLES
# ============================================

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

# ============================================
# VARIABLES GLOBALES
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
# FONCTIONS UTILITAIRES
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

pause() {
    echo ""
    echo -ne "${DIM}Appuyez sur [ENTRÉE] pour continuer...${NC}"
    read
}

# Fonction pour valider et formater les nombres
validate_number() {
    local num=$1
    local default=${2:-0}
    
    # Supprimer les espaces
    num=$(echo "$num" | tr -d ' ')
    
    # Si vide ou non numérique, retourner la valeur par défaut
    if [[ -z "$num" ]] || ! [[ "$num" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "$default"
        return
    fi
    
    echo "$num"
}

# Fonction sécurisée pour les calculs bc
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

# ============================================
# INSTALLATION DES DÉPENDANCES
# ============================================

install_dependencies() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Installation - System Benchmark Tool     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Impossible de détecter la distribution${NC}"
        return 1
    fi

    echo -e "${GREEN}Distribution détectée: $PRETTY_NAME${NC}"
    echo ""

    case $OS in
        ubuntu|debian|pop)
            echo -e "${YELLOW}Installation des dépendances avec apt...${NC}"
            sudo apt update
            sudo apt install -y sysbench fio mesa-utils jq bc
            ;;
        
        fedora|rhel|centos)
            echo -e "${YELLOW}Installation des dépendances avec dnf...${NC}"
            sudo dnf install -y sysbench fio mesa-demos jq bc
            ;;
        
        arch|manjaro)
            echo -e "${YELLOW}Installation des dépendances avec pacman...${NC}"
            sudo pacman -S --noconfirm sysbench fio mesa-utils jq bc
            ;;
        
        opensuse*)
            echo -e "${YELLOW}Installation des dépendances avec zypper...${NC}"
            sudo zypper install -y sysbench fio Mesa-demo-x jq bc
            ;;
        
        *)
            echo -e "${RED}Distribution non supportée: $OS${NC}"
            echo "Installez manuellement: sysbench fio mesa-utils jq bc"
            return 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}✓ Installation terminée avec succès !${NC}"
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
        echo -e "${YELLOW}${BOLD}Voulez-vous installer les dépendances maintenant ? (o/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Oo]$ ]]; then
            install_dependencies
            return 0
        else
            echo ""
            echo -e "${YELLOW}${BOLD}Installation manuelle requise:${NC}"
            echo -e "  ${WHITE}Ubuntu/Debian:${NC} sudo apt install sysbench fio mesa-utils bc jq"
            echo -e "  ${WHITE}Fedora/RHEL:${NC}   sudo dnf install sysbench fio mesa-demos bc jq"
            echo -e "  ${WHITE}Arch:${NC}          sudo pacman -S sysbench fio mesa-utils bc jq"
            echo ""
            return 1
        fi
    fi
    
    print_success "Toutes les dépendances sont installées !"
    sleep 1
    return 0
}

# ============================================
# FONCTIONS DE BENCHMARK
# ============================================

display_score() {
    local label=$1
    local score=$2
    local max=$3
    local icon=$4
    
    # Validation du score
    score=$(validate_number "$score" 0)
    
    local percentage=$(safe_calc "($score * 100) / $max" 0)
    percentage=${percentage%.*}
    
    local color=$RED
    if [ $percentage -gt 40 ]; then color=$YELLOW; fi
    if [ $percentage -gt 70 ]; then color=$GREEN; fi
    
    printf "${icon} ${WHITE}${BOLD}${label}:${NC} ${color}${BOLD}%.1f${NC}/%d\n" "$score" "$max"
    
    local bar_length=30
    local filled=$(safe_calc "($percentage * $bar_length) / 100" 0)
    filled=${filled%.*}
    local empty=$((bar_length - filled))
    
    printf "   ${color}["
    if [ $filled -gt 0 ]; then
        printf "%${filled}s" | tr ' ' '▰'
    fi
    if [ $empty -gt 0 ]; then
        printf "%${empty}s" | tr ' ' '▱'
    fi
    printf "]${NC} ${DIM}%d%%${NC}\n\n" $percentage
}

get_system_info() {
    section_header "Informations Système" "💻"
    
    echo "=== SYSTEM INFO ===" >> "$RESULTS_FILE"
    
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs 2>/dev/null)
    if [ -z "$CPU_MODEL" ]; then
        VENDOR=$(lscpu | grep "Vendor ID" | cut -d':' -f2 | xargs 2>/dev/null)
        CPU_MODEL="Processeur ${VENDOR:-Inconnu}"
    fi
    
    CPU_THREADS=$(nproc)
    CPU_CORES=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}' 2>/dev/null)
    if [ -z "$CPU_CORES" ]; then
        CPU_CORES=$CPU_THREADS
    fi
    
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
    
    sysbench cpu --cpu-max-prime=20000 --threads=1 run > /tmp/cpu_single.txt 2>&1
    
    local single_result=$(grep "events per second" /tmp/cpu_single.txt | awk '{print $4}')
    single_result=$(validate_number "$single_result" 100)
    
    echo -e "${WHITE}Single-thread:${NC} ${GREEN}${BOLD}${single_result}${NC} events/sec"
    echo ""
    
    print_info "Test multi-thread avec ${CPU_THREADS} threads..."
    echo ""
    
    sysbench cpu --cpu-max-prime=20000 --threads=$CPU_THREADS run > /tmp/cpu_multi.txt 2>&1
    
    local multi_result=$(grep "events per second" /tmp/cpu_multi.txt | awk '{print $4}')
    multi_result=$(validate_number "$multi_result" 500)
    
    echo -e "${WHITE}Multi-thread:${NC}  ${GREEN}${BOLD}${multi_result}${NC} events/sec"
    echo ""
    
    # Calcul du score avec validation
    local single_score=$(safe_calc "($single_result / 2000) * 50" 0)
    local multi_score=$(safe_calc "($multi_result / 16000) * 50" 0)
    CPU_SCORE=$(safe_calc "$single_score + $multi_score" 0)
    
    # Limiter à 100
    local cpu_int=${CPU_SCORE%.*}
    if [ $cpu_int -gt 100 ]; then
        CPU_SCORE=100
    fi
    
    display_score "Score CPU" "$CPU_SCORE" "100" "🖥️"
    
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
    
    sysbench memory --memory-block-size=1M --memory-total-size=10G --threads=4 run > /tmp/ram_test.txt 2>&1
    
    # Extraction plus robuste du débit mémoire
    local mem_speed=$(grep "transferred" /tmp/ram_test.txt | grep -oP '\d+\.\d+' | head -1)
    
    # Si pas trouvé, essayer une autre méthode
    if [ -z "$mem_speed" ]; then
        mem_speed=$(grep "MiB/sec" /tmp/ram_test.txt | awk '{print $(NF-1)}' | head -1)
    fi
    
    mem_speed=$(validate_number "$mem_speed" 1000)
    
    echo -e "${WHITE}Vitesse:${NC} ${GREEN}${BOLD}${mem_speed}${NC} MiB/sec"
    echo ""
    
    RAM_SCORE=$(safe_calc "($mem_speed / 10000) * 100" 0)
    
    # Limiter à 100
    local ram_int=${RAM_SCORE%.*}
    if [ $ram_int -gt 100 ]; then
        RAM_SCORE=100
    fi
    
    display_score "Score RAM" "$RAM_SCORE" "100" "💾"
    
    {
        echo "Vitesse: $mem_speed MiB/sec"
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
    
    fio --name=seq_write --directory="$test_dir" --rw=write --bs=1M --size=1G --numjobs=1 --runtime=20 --time_based --group_reporting --output-format=json > /tmp/fio_write.json 2>&1
    
    local seq_write=$(jq -r '.jobs[0].write.bw_bytes' /tmp/fio_write.json 2>/dev/null)
    seq_write=$(validate_number "$seq_write" 10485760)
    seq_write=$(safe_calc "$seq_write / 1048576" 10)
    
    echo -e "${WHITE}Écriture:${NC} ${GREEN}${BOLD}$(printf "%.2f" $seq_write)${NC} MiB/s"
    echo ""
    
    print_info "Test lecture séquentielle..."
    echo ""
    
    fio --name=seq_read --directory="$test_dir" --rw=read --bs=1M --size=1G --numjobs=1 --runtime=20 --time_based --group_reporting --output-format=json > /tmp/fio_read.json 2>&1
    
    local seq_read=$(jq -r '.jobs[0].read.bw_bytes' /tmp/fio_read.json 2>/dev/null)
    seq_read=$(validate_number "$seq_read" 20971520)
    seq_read=$(safe_calc "$seq_read / 1048576" 20)
    
    echo -e "${WHITE}Lecture:${NC}  ${GREEN}${BOLD}$(printf "%.2f" $seq_read)${NC} MiB/s"
    echo ""
    
    print_info "Test IOPS aléatoires (4K)..."
    echo ""
    
    fio --name=rand_rw --directory="$test_dir" --rw=randrw --bs=4K --size=512M --numjobs=4 --runtime=15 --time_based --group_reporting --output-format=json > /tmp/fio_rand.json 2>&1
    
    local rand_iops=$(jq -r '.jobs[0].read.iops' /tmp/fio_rand.json 2>/dev/null)
    rand_iops=$(validate_number "$rand_iops" 1000)
    rand_iops=${rand_iops%.*}
    
    echo -e "${WHITE}IOPS:${NC}     ${GREEN}${BOLD}${rand_iops}${NC}"
    echo ""
    
    rm -rf "$test_dir"
    rm -f /tmp/fio_*.json
    
    local seq_score=$(safe_calc "($seq_read / 3000) * 50" 0)
    local iops_score=$(safe_calc "($rand_iops / 50000) * 50" 0)
    DISK_SCORE=$(safe_calc "$seq_score + $iops_score" 0)
    
    # Limiter à 100
    local disk_int=${DISK_SCORE%.*}
    if [ $disk_int -gt 100 ]; then
        DISK_SCORE=100
    fi
    
    display_score "Score Disque" "$DISK_SCORE" "100" "💿"
    
    {
        echo "Écriture: $(printf "%.2f" $seq_write) MiB/s"
        echo "Lecture: $(printf "%.2f" $seq_read) MiB/s"
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
        print_warning "Test GPU non disponible (pas d'environnement graphique)"
        GPU_SCORE=50
        echo "GPU: 50.00/100 (test non disponible)" >> "$RESULTS_FILE"
        display_score "Score GPU" "$GPU_SCORE" "100" "🎮"
        echo ""
        sleep 1
        return
    fi
    
    print_info "Test de rendu OpenGL (10 secondes)..."
    echo ""
    
    timeout 11s glxgears 2>&1 | tee /tmp/glxgears.log &
    local pid=$!
    
    sleep 11
    kill $pid 2>/dev/null || true
    wait $pid 2>/dev/null || true
    
    local fps=$(grep "frames in" /tmp/glxgears.log | tail -1 | awk '{print $6}' | tr -d ' ')
    fps=$(validate_number "$fps" 500)
    
    echo -e "${WHITE}FPS OpenGL:${NC} ${GREEN}${BOLD}$(printf "%.0f" $fps)${NC}"
    echo ""
    
    GPU_SCORE=$(safe_calc "($fps / 2000) * 100" 0)
    
    # Limiter à 100
    local gpu_int=${GPU_SCORE%.*}
    if [ $gpu_int -gt 100 ]; then
        GPU_SCORE=100
    fi
    
    display_score "Score GPU" "$GPU_SCORE" "100" "🎮"
    
    {
        echo "FPS: $(printf "%.0f" $fps)"
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
    sleep 1
    echo ""
    
    # Validation de tous les scores
    CPU_SCORE=$(validate_number "$CPU_SCORE" 0)
    RAM_SCORE=$(validate_number "$RAM_SCORE" 0)
    DISK_SCORE=$(validate_number "$DISK_SCORE" 0)
    GPU_SCORE=$(validate_number "$GPU_SCORE" 0)
    
    FINAL_SCORE=$(safe_calc "($CPU_SCORE * 0.35) + ($RAM_SCORE * 0.20) + ($DISK_SCORE * 0.30) + ($GPU_SCORE * 0.15)" 0)
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                    ${WHITE}${BOLD}TABLEAU DES SCORES${NC}                           ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    print_score_line() {
        local icon=$1
        local name=$2
        local score=$3
        local weight=$4
        
        score=$(validate_number "$score" 0)
        local int_score=${score%.*}
        
        local color=$RED
        if [ $int_score -gt 40 ]; then color=$YELLOW; fi
        if [ $int_score -gt 70 ]; then color=$GREEN; fi
        
        local bar_length=20
        local filled=$(safe_calc "($int_score * $bar_length) / 100" 0)
        filled=${filled%.*}
        local empty=$((bar_length - filled))
        
        printf "${BOLD}${CYAN}║${NC} ${icon}  %-10s ${color}[" "$name"
        if [ $filled -gt 0 ]; then
            printf "%${filled}s" | tr ' ' '▰'
        fi
        if [ $empty -gt 0 ]; then
            printf "%${empty}s" | tr ' ' '▱'
        fi
        printf "]${NC} ${color}${BOLD}%5.1f${NC}/100 ${DIM}(%s)${NC} ${BOLD}${CYAN}║${NC}\n" "$score" "$weight"
    }
    
    print_score_line "🖥️ " "CPU" "$CPU_SCORE" "35%"
    print_score_line "💾" "RAM" "$RAM_SCORE" "20%"
    print_score_line "💿" "Disque" "$DISK_SCORE" "30%"
    print_score_line "🎮" "GPU" "$GPU_SCORE" "15%"
    
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    local int_final=${FINAL_SCORE%.*}
    if [ -z "$int_final" ]; then int_final=0; fi
    
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

run_benchmark() {
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
    ║                           version 2.1                                 ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "\n${CYAN}${BOLD}${GEAR} Initialisation du système de benchmark...${NC}\n"
    sleep 1
    
    echo -e "${YELLOW}${BOLD}⏱️  Durée estimée: 5-10 minutes${NC}"
    echo -e "${DIM}Fermez les applications gourmandes pour des résultats optimaux${NC}\n"
    echo -ne "${WHITE}Appuyez sur ${BOLD}[ENTRÉE]${NC}${WHITE} pour démarrer...${NC}"
    read
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    RESULTS_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}.txt"
    
    check_dependencies || return
    get_system_info
    test_cpu
    test_ram
    test_disk
    test_gpu
    calculate_final_score
    
    echo ""
    section_header "Benchmark Terminé !" "🎉"
    
    echo -e "${GREEN}${BOLD}${CHECK} Résultats sauvegardés:${NC}"
    echo -e "   ${WHITE}${UNDERLINE}$RESULTS_FILE${NC}"
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================
# COMPARAISON DE BENCHMARKS
# ============================================

compare_benchmarks() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    cat << "BANNER_EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     ██████╗ ██████╗ ███╗   ███╗██████╗  █████╗ ██████╗ ███████╗      ║
║    ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔════╝      ║
║    ██║     ██║   ██║██╔████╔██║██████╔╝███████║██████╔╝█████╗        ║
║    ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║██╔══██╗██╔══╝        ║
║    ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║██║  ██║███████╗      ║
║     ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝      ║
║                                                                       ║
║                    Comparaison de Benchmarks                          ║
╚═══════════════════════════════════════════════════════════════════════╝
BANNER_EOF
    echo -e "${NC}\n"

    if [ ! -d "$RESULTS_DIR" ]; then
        echo -e "${RED}✗ Aucun résultat trouvé${NC}"
        return
    fi

    files=($(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null))

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}✗ Aucun résultat de benchmark trouvé${NC}"
        return
    fi

    echo -e "${CYAN}${BOLD}📊 Résultats disponibles:${NC}\n"

    for i in "${!files[@]}"; do
        filename=$(basename "${files[$i]}")
        date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//')
        date_formatted=$(echo "$date" | sed 's/_/ - /')
        score=$(grep "SCORE FINAL:" "${files[$i]}" | awk '{print $3}' | cut -d'/' -f1 2>/dev/null)
        
        local color=$RED
        if [ -n "$score" ]; then
            score=$(validate_number "$score" 0)
            local int_score=${score%.*}
            if [ $int_score -gt 70 ]; then color=$GREEN; elif [ $int_score -gt 40 ]; then color=$YELLOW; fi
        fi
        
        if [ -n "$score" ]; then
            printf "   ${WHITE}%2d.${NC} %s ${DIM}│${NC} Score: ${color}${BOLD}%.1f${NC}/100\n" $((i+1)) "$date_formatted" "$score"
        else
            printf "   ${WHITE}%2d.${NC} %s ${DIM}│${NC} Score: ${YELLOW}N/A${NC}\n" $((i+1)) "$date_formatted"
        fi
    done

    echo ""

    if [ ${#files[@]} -eq 1 ]; then
        echo -e "${CYAN}${BOLD}ℹ${NC}  Un seul résultat disponible"
        echo ""
        cat "${files[0]}"
        return
    fi

    echo -ne "${CYAN}${BOLD}Benchmark 1 →${NC} "
    read choice1

    if ! [[ "$choice1" =~ ^[0-9]+$ ]] || [ "$choice1" -lt 1 ] || [ "$choice1" -gt "${#files[@]}" ]; then
        echo -e "${RED}✗ Choix invalide${NC}"
        return
    fi

    echo -ne "${CYAN}${BOLD}Benchmark 2 →${NC} "
    read choice2

    if ! [[ "$choice2" =~ ^[0-9]+$ ]] || [ "$choice2" -lt 1 ] || [ "$choice2" -gt "${#files[@]}" ]; then
        echo -e "${RED}✗ Choix invalide${NC}"
        return
    fi

    file1="${files[$((choice1-1))]}"
    file2="${files[$((choice2-1))]}"

    extract_score() {
        local score=$(grep "^$1:" "$2" | grep -oP '\d+\.\d+' | head -1)
        echo "$(validate_number "$score" 0)"
    }

    cpu1=$(extract_score "CPU" "$file1")
    ram1=$(extract_score "RAM" "$file1")
    disk1=$(extract_score "Disque" "$file1")
    gpu1=$(extract_score "GPU" "$file1")
    final1=$(extract_score "SCORE FINAL" "$file1")

    cpu2=$(extract_score "CPU" "$file2")
    ram2=$(extract_score "RAM" "$file2")
    disk2=$(extract_score "Disque" "$file2")
    gpu2=$(extract_score "GPU" "$file2")
    final2=$(extract_score "SCORE FINAL" "$file2")

    calc_diff() { 
        local diff=$(safe_calc "$1 - $2" 0)
        echo "$diff"
    }
    
    calc_percent() {
        local val=$(validate_number "$2" 1)
        if (( $(echo "$val != 0" | bc -l 2>/dev/null || echo "0") )); then
            local percent=$(safe_calc "(($1 - $2) / $2) * 100" 0)
            echo "$percent"
        else
            echo "0"
        fi
    }

    cpu_diff=$(calc_diff "$cpu2" "$cpu1")
    ram_diff=$(calc_diff "$ram2" "$ram1")
    disk_diff=$(calc_diff "$disk2" "$disk1")
    gpu_diff=$(calc_diff "$gpu2" "$gpu1")
    final_diff=$(calc_diff "$final2" "$final1")

    cpu_percent=$(calc_percent "$cpu2" "$cpu1")
    ram_percent=$(calc_percent "$ram2" "$ram1")
    disk_percent=$(calc_percent "$disk2" "$disk1")
    gpu_percent=$(calc_percent "$gpu2" "$gpu1")
    final_percent=$(calc_percent "$final2" "$final1")

    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                            ${WHITE}${BOLD}COMPARAISON DÉTAILLÉE${NC}                                ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

    date1=$(basename "$file1" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
    date2=$(basename "$file2" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')

    printf "${BOLD}${CYAN}║${NC} ${WHITE}Benchmark 1:${NC} %-64s ${BOLD}${CYAN}║${NC}\n" "$date1"
    printf "${BOLD}${CYAN}║${NC} ${WHITE}Benchmark 2:${NC} %-64s ${BOLD}${CYAN}║${NC}\n" "$date2"
    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

    print_comparison_row() {
        local icon=$1
        local name=$2
        local val1=$3
        local val2=$4
        local diff=$5
        local percent=$6
        
        val1=$(validate_number "$val1" 0)
        val2=$(validate_number "$val2" 0)
        diff=$(validate_number "$diff" 0)
        percent=$(validate_number "$percent" 0)
        
        local color=$NC
        local arrow=""
        if (( $(echo "$diff > 0.5" | bc -l 2>/dev/null || echo "0") )); then
            color=$GREEN
            arrow="↑"
        elif (( $(echo "$diff < -0.5" | bc -l 2>/dev/null || echo "0") )); then
            color=$YELLOW
            arrow="↓"
        else
            arrow="="
        fi
        
        printf "${BOLD}${CYAN}║${NC} ${icon}  %-8s ${DIM}│${NC}" "$name"
        printf " ${WHITE}%6.1f${NC} ${DIM}→${NC} ${color}${BOLD}%6.1f${NC}" "$val1" "$val2"
        printf " ${color}${BOLD}${arrow} %+6.1f%%${NC}" "$percent"
        
        local abs_percent=${percent#-}
        abs_percent=${abs_percent%.*}
        if [ $abs_percent -gt 5 ]; then
            local bar_len=$(safe_calc "$abs_percent / 5" 1)
            bar_len=${bar_len%.*}
            if [ $bar_len -gt 10 ]; then bar_len=10; fi
            printf " ${color}"
            if [ $bar_len -gt 0 ]; then
                printf "%${bar_len}s" | tr ' ' '▰'
            fi
            printf "${NC}"
        fi
        
        printf "            ${BOLD}${CYAN}║${NC}\n"
    }

    print_comparison_row "🖥️ " "CPU" "$cpu1" "$cpu2" "$cpu_diff" "$cpu_percent"
    print_comparison_row "💾" "RAM" "$ram1" "$ram2" "$ram_diff" "$ram_percent"
    print_comparison_row "💿" "Disque" "$disk1" "$disk2" "$disk_diff" "$disk_percent"
    print_comparison_row "🎮" "GPU" "$gpu1" "$gpu2" "$gpu_diff" "$gpu_percent"

    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

    local final_color=$NC
    local final_arrow=""
    if (( $(echo "$final_diff > 0.5" | bc -l 2>/dev/null || echo "0") )); then
        final_color=$GREEN
        final_arrow="↑"
    elif (( $(echo "$final_diff < -0.5" | bc -l 2>/dev/null || echo "0") )); then
        final_color=$YELLOW
        final_arrow="↓"
    else
        final_arrow="="
    fi

    printf "${BOLD}${CYAN}║${NC} ${WHITE}${BOLD}FINAL${NC}    ${DIM}│${NC}"
    printf " ${WHITE}%6.1f${NC} ${DIM}→${NC} ${final_color}${BOLD}%6.1f${NC}" "$final1" "$final2"
    printf " ${final_color}${BOLD}${final_arrow} %+6.1f%%${NC}" "$final_percent"

    local abs_final=${final_percent#-}
    abs_final=${abs_final%.*}
    if [ $abs_final -gt 5 ]; then
        local bar_len=$(safe_calc "$abs_final / 3" 1)
        bar_len=${bar_len%.*}
        if [ $bar_len -gt 15 ]; then bar_len=15; fi
        printf " ${final_color}"
        if [ $bar_len -gt 0 ]; then
            printf "%${bar_len}s" | tr ' ' '█'
        fi
        printf "${NC}"
    fi

    printf "     ${BOLD}${CYAN}║${NC}\n"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════════╝${NC}"

    echo ""
    if (( $(echo "$final_diff > 5" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "   ${GREEN}${BOLD}✓ Le benchmark 2 est meilleur${NC} ${GREEN}(+$(printf "%.1f" "$final_percent")%)${NC}"
    elif (( $(echo "$final_diff < -5" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "   ${YELLOW}${BOLD}⚠ Le benchmark 2 est moins bon${NC} ${YELLOW}($(printf "%.1f" "$final_percent")%)${NC}"
    else
        echo -e "   ${BLUE}${BOLD}≈ Performances similaires${NC}"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}📈 Changements significatifs:${NC}\n"

    show_change() {
        local name=$1
        local percent=$2
        
        percent=$(validate_number "$percent" 0)
        local abs=${percent#-}
        abs=${abs%.*}
        
        if [ $abs -gt 10 ]; then
            if (( $(echo "$percent > 0" | bc -l 2>/dev/null || echo "0") )); then
                echo -e "   ${GREEN}↑${NC} $name: ${GREEN}+$(printf "%.1f" $percent)%${NC}"
            else
                echo -e "   ${YELLOW}↓${NC} $name: ${YELLOW}$(printf "%.1f" $percent)%${NC}"
            fi
        fi
    }

    show_change "CPU" "$cpu_percent"
    show_change "RAM" "$ram_percent"
    show_change "Disque" "$disk_percent"
    show_change "GPU" "$gpu_percent"

    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================
# GÉNÉRATION DE RAPPORT HTML
# ============================================

generate_html_report() {
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         Génération de Rapport HTML - Benchmark                ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

    if [ ! -d "$RESULTS_DIR" ]; then
        echo -e "${YELLOW}Aucun résultat trouvé${NC}"
        return
    fi

    files=($(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null))

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Aucun résultat de benchmark trouvé${NC}"
        return
    fi

    echo -e "${BLUE}Sélection du fichier à convertir :${NC}\n"

    for i in "${!files[@]}"; do
        filename=$(basename "${files[$i]}")
        date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
        printf "%2d. %s\n" $((i+1)) "$date"
    done

    echo ""
    echo -n "Choisissez un fichier (1-${#files[@]}): "
    read choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#files[@]}" ]; then
        echo -e "${YELLOW}Choix invalide${NC}"
        return
    fi

    selected_file="${files[$((choice-1))]}"

    extract_score() {
        local file=$1
        local component=$2
        
        local score=$(grep "^$component:" "$file" | grep -oP '\d+\.\d+' | head -1)
        echo "$(validate_number "$score" 0)"
    }

    extract_sys_info() {
        local file=$1
        local field=$2
        
        case $field in
            "CPU_MODEL")
                grep "^CPU:" "$file" | head -1 | sed 's/CPU: //' | sed 's/ (.*//g'
                ;;
            "RAM_TOTAL")
                grep "^RAM:" "$file" | head -1 | sed 's/RAM: //'
                ;;
            "GPU_INFO")
                grep "^GPU:" "$file" | head -1 | sed 's/GPU: //'
                ;;
        esac
    }

    echo ""
    echo -e "${CYAN}Extraction des données...${NC}"

    filename=$(basename "$selected_file")
    bench_date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')

    cpu_score=$(extract_score "$selected_file" "CPU")
    ram_score=$(extract_score "$selected_file" "RAM")
    disk_score=$(extract_score "$selected_file" "Disque")
    gpu_score=$(extract_score "$selected_file" "GPU")
    final_score=$(extract_score "$selected_file" "SCORE FINAL")

    cpu_model=$(extract_sys_info "$selected_file" "CPU_MODEL")
    ram_total=$(extract_sys_info "$selected_file" "RAM_TOTAL")
    gpu_info=$(extract_sys_info "$selected_file" "GPU_INFO")

    cpu_model=${cpu_model:-"Non détecté"}
    ram_total=${ram_total:-"Non détecté"}
    gpu_info=${gpu_info:-"Non détecté"}

    int_score=${final_score%.*}
    if [ -z "$int_score" ]; then int_score=0; fi

    if [ $int_score -ge 80 ]; then
        category="excellent"
        category_text="🏆 EXCELLENT"
    elif [ $int_score -ge 60 ]; then
        category="good"
        category_text="✨ BON"
    elif [ $int_score -ge 40 ]; then
        category="average"
        category_text="👍 MOYEN"
    else
        category="low"
        category_text="⚠️ FAIBLE"
    fi

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$REPORTS_DIR/report_${TIMESTAMP}.html"

    cat > "$OUTPUT_FILE" << 'HTML_START'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
HTML_START

    echo "    <title>Rapport de Benchmark - $bench_date</title>" >> "$OUTPUT_FILE"

    cat >> "$OUTPUT_FILE" << 'HTML_STYLE'
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        
        header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .benchmark-card {
            background: #f8f9fa;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .benchmark-card h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.8em;
        }
        
        .system-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: white;
            padding: 15px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        
        .info-item strong {
            color: #667eea;
            display: block;
            margin-bottom: 5px;
        }
        
        .score-overview {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .score-item {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 15px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            transition: transform 0.3s;
        }
        
        .score-item:hover {
            transform: translateY(-5px);
        }
        
        .score-item h3 {
            font-size: 1.2em;
            margin-bottom: 10px;
            opacity: 0.9;
        }
        
        .score-value {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .score-label {
            font-size: 0.9em;
            opacity: 0.8;
        }
        
        .final-score {
            background: white;
            border: 5px solid #667eea;
            color: #667eea;
            grid-column: 1 / -1;
        }
        
        .final-score .score-value {
            color: #667eea;
            font-size: 4em;
        }
        
        .chart-container {
            margin: 30px 0;
            background: white;
            padding: 20px;
            border-radius: 15px;
            max-height: 400px;
        }
        
        .category-badge {
            display: inline-block;
            padding: 10px 20px;
            border-radius: 25px;
            font-weight: bold;
            font-size: 1.2em;
            margin-top: 20px;
        }
        
        .excellent {
            background: #10b981;
            color: white;
        }
        
        .good {
            background: #3b82f6;
            color: white;
        }
        
        .average {
            background: #f59e0b;
            color: white;
        }
        
        .low {
            background: #ef4444;
            color: white;
        }
        
        footer {
            background: #f8f9fa;
            text-align: center;
            padding: 20px;
            color: #666;
            border-top: 1px solid #e0e0e0;
        }
        
        .timestamp {
            font-size: 0.9em;
            color: #666;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Rapport de Benchmark Système</h1>
            <p>Analyse complète des performances</p>
        </header>
        
        <div class="content">
HTML_STYLE

    cat >> "$OUTPUT_FILE" << HTML_CONTENT
            <div class="benchmark-card">
                <h2>📊 Benchmark du $bench_date</h2>
                
                <div class="system-info">
                    <div class="info-item">
                        <strong>Processeur</strong>
                        $cpu_model
                    </div>
                    <div class="info-item">
                        <strong>Mémoire</strong>
                        $ram_total
                    </div>
                    <div class="info-item">
                        <strong>GPU</strong>
                        $gpu_info
                    </div>
                </div>
                
                <div class="score-overview">
                    <div class="score-item">
                        <h3>🖥️ CPU</h3>
                        <div class="score-value">$(printf "%.1f" $cpu_score)</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>💾 RAM</h3>
                        <div class="score-value">$(printf "%.1f" $ram_score)</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>💿 Disque</h3>
                        <div class="score-value">$(printf "%.1f" $disk_score)</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>🎮 GPU</h3>
                        <div class="score-value">$(printf "%.1f" $gpu_score)</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item final-score">
                        <h3>Score Final</h3>
                        <div class="score-value">$(printf "%.1f" $final_score)</div>
                        <div class="score-label">/100</div>
                        <div class="category-badge $category">$category_text</div>
                    </div>
                </div>
                
                <div class="chart-container">
                    <canvas id="radarChart"></canvas>
                </div>
                
                <script>
                    const ctx = document.getElementById('radarChart').getContext('2d');
                    new Chart(ctx, {
                        type: 'radar',
                        data: {
                            labels: ['CPU', 'RAM', 'Disque', 'GPU'],
                            datasets: [{
                                label: 'Scores',
                                data: [$(printf "%.1f" $cpu_score), $(printf "%.1f" $ram_score), $(printf "%.1f" $disk_score), $(printf "%.1f" $gpu_score)],
                                fill: true,
                                backgroundColor: 'rgba(102, 126, 234, 0.2)',
                                borderColor: 'rgb(102, 126, 234)',
                                pointBackgroundColor: 'rgb(102, 126, 234)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'rgb(102, 126, 234)',
                                pointRadius: 5,
                                pointHoverRadius: 7
                            }]
                        },
                        options: {
                            elements: {
                                line: {
                                    borderWidth: 3
                                }
                            },
                            scales: {
                                r: {
                                    angleLines: {
                                        display: true
                                    },
                                    suggestedMin: 0,
                                    suggestedMax: 100,
                                    ticks: {
                                        stepSize: 20
                                    }
                                }
                            },
                            plugins: {
                                legend: {
                                    display: false
                                }
                            }
                        }
                    });
                </script>
            </div>
HTML_CONTENT

    cat >> "$OUTPUT_FILE" << 'HTML_END'
        </div>
        
        <footer>
            <p><strong>System Benchmark Tool v2.1</strong></p>
            <p class="timestamp">Rapport généré le
HTML_END

    echo " $(date '+%d/%m/%Y à %H:%M:%S')</p>" >> "$OUTPUT_FILE"

    cat >> "$OUTPUT_FILE" << 'HTML_FINAL'
        </footer>
    </div>
</body>
</html>
HTML_FINAL

    echo ""
    echo -e "${GREEN}✓ Rapport HTML généré avec succès !${NC}"
    echo ""
    echo -e "${BLUE}Fichier de sortie :${NC} $OUTPUT_FILE"
    echo ""
    echo -e "${CYAN}Pour ouvrir le rapport :${NC}"
    echo "  xdg-open $OUTPUT_FILE"
    echo ""
}

# ============================================
# AFFICHAGE DES RÉSULTATS
# ============================================

show_results() {
    clear
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                   ${WHITE}${BOLD}HISTORIQUE DES BENCHMARKS${NC}                  ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"
    
    if [ ! -d "$RESULTS_DIR" ]; then
        echo -e "${YELLOW}Aucun résultat trouvé${NC}\n"
        return
    fi
    
    local files=($(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Aucun benchmark effectué${NC}\n"
        return
    fi
    
    echo -e "${WHITE}${BOLD}Total: ${#files[@]} benchmark(s)${NC}\n"
    
    for file in "${files[@]}"; do
        local filename=$(basename "$file")
        local date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
        local score=$(grep "SCORE FINAL:" "$file" | awk '{print $3}' | cut -d'/' -f1 2>/dev/null)
        
        score=$(validate_number "$score" 0)
        
        if [ -n "$score" ]; then
            local int_score=${score%.*}
            local color=$RED
            local badge="⚠️ "
            
            if [ $int_score -ge 80 ]; then
                color=$GREEN
                badge="🏆"
            elif [ $int_score -ge 60 ]; then
                color=$CYAN
                badge="✨"
            elif [ $int_score -ge 40 ]; then
                color=$YELLOW
                badge="👍"
            fi
            
            echo -e "${badge} ${WHITE}${date}${NC}"
            echo -e "   Score: ${color}${BOLD}$(printf "%.1f" $score)${NC}/100"
            
            local cpu=$(grep "^CPU:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local ram=$(grep "^RAM:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local disk=$(grep "^Disque:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local gpu=$(grep "^GPU:" "$file" | grep -oP '\d+\.\d+' | head -1)
            
            cpu=$(validate_number "$cpu" 0)
            ram=$(validate_number "$ram" 0)
            disk=$(validate_number "$disk" 0)
            gpu=$(validate_number "$gpu" 0)
            
            printf "   ${DIM}CPU: %.1f │ RAM: %.1f │ Disque: %.1f │ GPU: %.1f${NC}\n\n" "$cpu" "$ram" "$disk" "$gpu"
        fi
    done
}

# ============================================
# GUIDE D'OPTIMISATION
# ============================================

show_guide() {
    clear
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                   ${WHITE}${BOLD}GUIDE D'OPTIMISATION${NC}                       ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${WHITE}${BOLD}💡 Optimisations Gratuites (0€)${NC}\n"
    echo -e "  ${GREEN}✓${NC} Activer XMP/DOCP dans le BIOS ${GREEN}(+10-15 points RAM)${NC}"
    echo -e "  ${GREEN}✓${NC} Installer drivers propriétaires GPU ${GREEN}(+20-30 points GPU)${NC}"
    echo -e "  ${GREEN}✓${NC} Mode performance CPU dans le BIOS ${GREEN}(+5-10 points CPU)${NC}"
    echo -e "  ${GREEN}✓${NC} Nettoyer la poussière ${GREEN}(+5 points)${NC}"
    echo -e "  ${GREEN}✓${NC} Fermer les apps en arrière-plan ${GREEN}(+3-5 points)${NC}\n"
    
    echo -e "${WHITE}${BOLD}💰 Upgrades par Rentabilité${NC}\n"
    echo -e "  ${YELLOW}1.${NC} ${BOLD}HDD → SSD${NC} (50-80€) ${GREEN}Impact: ÉNORME${NC}"
    echo -e "     De 30 points → 70+ points disque"
    echo -e "  ${YELLOW}2.${NC} ${BOLD}RAM 8GB → 16GB${NC} (40-60€) ${CYAN}Impact: Bon${NC}"
    echo -e "     +8-12 points RAM"
    echo -e "  ${YELLOW}3.${NC} ${BOLD}CPU Upgrade${NC} (150-300€) ${CYAN}Impact: Moyen-Élevé${NC}"
    echo -e "     +15-30 points CPU"
    echo -e "  ${YELLOW}4.${NC} ${BOLD}GPU Gaming${NC} (300-600€) ${BLUE}Impact: Variable${NC}"
    echo -e "     Important seulement si gaming\n"
    
    echo -e "${WHITE}${BOLD}🎯 Scores Cibles par Usage${NC}\n"
    echo -e "  ${GREEN}Gaming 1080p@144Hz:${NC}     Score > 70"
    echo -e "  ${CYAN}Workstation Dev:${NC}        Score > 65"
    echo -e "  ${YELLOW}Bureautique:${NC}            Score > 40"
    echo -e "  ${MAGENTA}Serveur/Homelab:${NC}       Score > 50\n"
}

# ============================================
# MENU PRINCIPAL
# ============================================

show_menu() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    cat << "MENU_EOF"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║    ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗       ║
    ║    ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗      ║
    ║    ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║      ║
    ║    ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║      ║
    ║    ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║      ║
    ║    ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝      ║
    ║                                                                       ║
    ║                     Professional Benchmark Suite                      ║
    ║                              v2.1                                     ║
    ╚═══════════════════════════════════════════════════════════════════════╝
MENU_EOF
    echo -e "${NC}\n"
    
    if [ -d "$RESULTS_DIR" ]; then
        local latest=$(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            local score=$(grep "SCORE FINAL:" "$latest" | awk '{print $3}' | cut -d'/' -f1)
            score=$(validate_number "$score" 0)
            local date=$(basename "$latest" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
            
            if [ -n "$score" ]; then
                local int_score=${score%.*}
                local color=$RED
                if [ $int_score -gt 70 ]; then color=$GREEN; elif [ $int_score -gt 40 ]; then color=$YELLOW; fi
                
                echo -e "${DIM}   Dernier benchmark: ${date}${NC}"
                echo -e "${DIM}   Score: ${color}${BOLD}$(printf "%.1f" $score)${NC}${DIM}/100${NC}\n"
            fi
        fi
    fi
    
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                        ${WHITE}${BOLD}MENU PRINCIPAL${NC}                          ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${GREEN}${BOLD}1.${NC} 🚀 ${WHITE}Lancer un nouveau benchmark${NC}                          ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Test complet du système (5-10 min)${NC}                     ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${BLUE}${BOLD}2.${NC} 📊 ${WHITE}Comparer deux benchmarks${NC}                              ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Analyse détaillée des différences${NC}                      ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${MAGENTA}${BOLD}3.${NC} 📄 ${WHITE}Générer un rapport HTML${NC}                             ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Rapport visuel avec graphiques${NC}                         ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${YELLOW}${BOLD}4.${NC} 📋 ${WHITE}Voir tous les résultats${NC}                              ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Liste de tous les benchmarks${NC}                           ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${CYAN}${BOLD}5.${NC} 📖 ${WHITE}Guide d'optimisation${NC}                                  ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Conseils pour améliorer les performances${NC}               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${WHITE}${BOLD}6.${NC} 🔧 ${WHITE}Installer les dépendances${NC}                            ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}     ${DIM}Installation automatique des outils${NC}                    ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${RED}${BOLD}0.${NC} ❌ ${WHITE}Quitter${NC}                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    while true; do
        show_menu
        echo -ne "${CYAN}${BOLD}Votre choix → ${NC}"
        read choice
        
        case $choice in
            1)
                run_benchmark
                pause
                ;;
            2)
                compare_benchmarks
                pause
                ;;
            3)
                generate_html_report
                pause
                ;;
            4)
                show_results
                pause
                ;;
            5)
                show_guide
                pause
                ;;
            6)
                install_dependencies
                pause
                ;;
            0)
                clear
                echo -e "\n${CYAN}${BOLD}👋 Merci d'avoir utilisé BenchmarkPro !${NC}\n"
                echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}Résultats sauvegardés dans:${NC} ${WHITE}$RESULTS_DIR${NC}"
                echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}${BOLD}✗ Choix invalide${NC}"
                sleep 1
                ;;
        esac
    done
}

# Lancer le programme
main