#!/bin/bash

# Script de comparaison de benchmarks - Version Belle

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

RESULTS_DIR="$HOME/benchmark_results"

# Bannière
clear
echo -e "${BOLD}${MAGENTA}"
cat << "EOF"
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
EOF
echo -e "${NC}\n"

# Vérifier les résultats
if [ ! -d "$RESULTS_DIR" ]; then
    echo -e "${RED}✗ Aucun résultat trouvé${NC}"
    exit 1
fi

files=($(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null))

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}✗ Aucun résultat de benchmark trouvé${NC}"
    exit 1
fi

# Liste des fichiers avec style
echo -e "${CYAN}${BOLD}📊 Résultats disponibles:${NC}\n"

for i in "${!files[@]}"; do
    filename=$(basename "${files[$i]}")
    date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//')
    date_formatted=$(echo "$date" | sed 's/_/ - /')
    score=$(grep "SCORE FINAL:" "${files[$i]}" | awk '{print $3}' | cut -d'/' -f1 2>/dev/null)
    
    # Couleur selon le score
    local color=$RED
    if [ -n "$score" ]; then
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

# Si un seul fichier
if [ ${#files[@]} -eq 1 ]; then
    echo -e "${CYAN}${BOLD}ℹ${NC}  Un seul résultat disponible"
    echo ""
    cat "${files[0]}"
    exit 0
fi

# Sélection
echo -ne "${CYAN}${BOLD}Benchmark 1 →${NC} "
read choice1

if ! [[ "$choice1" =~ ^[0-9]+$ ]] || [ "$choice1" -lt 1 ] || [ "$choice1" -gt "${#files[@]}" ]; then
    echo -e "${RED}✗ Choix invalide${NC}"
    exit 1
fi

echo -ne "${CYAN}${BOLD}Benchmark 2 →${NC} "
read choice2

if ! [[ "$choice2" =~ ^[0-9]+$ ]] || [ "$choice2" -lt 1 ] || [ "$choice2" -gt "${#files[@]}" ]; then
    echo -e "${RED}✗ Choix invalide${NC}"
    exit 1
fi

file1="${files[$((choice1-1))]}"
file2="${files[$((choice2-1))]}"

# Extraction des scores
extract_score() {
    grep "$1:" "$2" | grep -oP '\d+\.\d+' | head -1
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

# Calculs
calc_diff() { echo "scale=2; $1 - $2" | bc; }
calc_percent() {
    if [ "$2" != "0" ]; then
        echo "scale=2; (($1 - $2) / $2) * 100" | bc
    else
        echo "N/A"
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

# Affichage
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║${NC}                            ${WHITE}${BOLD}COMPARAISON DÉTAILLÉE${NC}                                ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

date1=$(basename "$file1" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
date2=$(basename "$file2" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')

printf "${BOLD}${CYAN}║${NC} ${WHITE}Benchmark 1:${NC} %-64s ${BOLD}${CYAN}║${NC}\n" "$date1"
printf "${BOLD}${CYAN}║${NC} ${WHITE}Benchmark 2:${NC} %-64s ${BOLD}${CYAN}║${NC}\n" "$date2"
echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

# Fonction d'affichage des lignes
print_comparison_row() {
    local icon=$1
    local name=$2
    local val1=$3
    local val2=$4
    local diff=$5
    local percent=$6
    
    local color=$NC
    local arrow=""
    if (( $(echo "$diff > 0" | bc -l) )); then
        color=$GREEN
        arrow="↑"
    elif (( $(echo "$diff < 0" | bc -l) )); then
        color=$YELLOW
        arrow="↓"
    else
        arrow="="
    fi
    
    printf "${BOLD}${CYAN}║${NC} ${icon} %-10s ${DIM}│${NC}" "$name"
    printf " ${WHITE}%6.1f${NC} ${DIM}→${NC} ${color}${BOLD}%6.1f${NC}" "$val1" "$val2"
    
    if [ "$percent" != "N/A" ]; then
        printf " ${color}${BOLD}${arrow} %+6.1f%%${NC}" "$percent"
    else
        printf " ${color}${BOLD}${arrow} %+6.1f${NC}" "$diff"
    fi
    
    # Barre de différence
    local abs_percent=${percent#-}
    abs_percent=${abs_percent%.*}
    if [ "$percent" != "N/A" ] && [ $abs_percent -gt 5 ]; then
        local bar_len=$((abs_percent / 5))
        if [ $bar_len -gt 10 ]; then bar_len=10; fi
        printf " ${color}"
        printf "%${bar_len}s" | tr ' ' '▰'
        printf "${NC}"
    fi
    
    printf "${BOLD}${CYAN}║${NC}\n"
}

print_comparison_row "🖥️ " "CPU" "$cpu1" "$cpu2" "$cpu_diff" "$cpu_percent"
print_comparison_row "💾" "RAM" "$ram1" "$ram2" "$ram_diff" "$ram_percent"
print_comparison_row "💿" "Disque" "$disk1" "$disk2" "$disk_diff" "$disk_percent"
print_comparison_row "🎮" "GPU" "$gpu1" "$gpu2" "$gpu_diff" "$gpu_percent"

echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════════════════════╣${NC}"

# Score final avec couleur appropriée
local final_color=$NC
local final_arrow=""
if (( $(echo "$final_diff > 0" | bc -l) )); then
    final_color=$GREEN
    final_arrow="↑"
elif (( $(echo "$final_diff < 0" | bc -l) )); then
    final_color=$YELLOW
    final_arrow="↓"
else
    final_arrow="="
fi

printf "${BOLD}${CYAN}║${NC} ${WHITE}${BOLD}FINAL${NC}      ${DIM}│${NC}"
printf " ${WHITE}%6.1f${NC} ${DIM}→${NC} ${final_color}${BOLD}%6.1f${NC}" "$final1" "$final2"
printf " ${final_color}${BOLD}${final_arrow} %+6.1f%%${NC}" "$final_percent"

# Grande barre pour le score final
local abs_final=${final_percent#-}
abs_final=${abs_final%.*}
if [ "$abs_final" != "N/A" ] && [ $abs_final -gt 5 ]; then
    local bar_len=$((abs_final / 3))
    if [ $bar_len -gt 15 ]; then bar_len=15; fi
    printf " ${final_color}"
    printf "%${bar_len}s" | tr ' ' '█'
    printf "${NC}"
fi

printf "     ${BOLD}${CYAN}║${NC}\n"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════════╝${NC}"

# Verdict
echo ""
if (( $(echo "$final_diff > 5" | bc -l) )); then
    echo -e "   ${GREEN}${BOLD}✓ Le benchmark 2 est meilleur${NC} ${GREEN}(+$(printf "%.1f" "$final_percent")%)${NC}"
elif (( $(echo "$final_diff < -5" | bc -l) )); then
    echo -e "   ${YELLOW}${BOLD}⚠ Le benchmark 2 est moins bon${NC} ${YELLOW}($(printf "%.1f" "$final_percent")%)${NC}"
else
    echo -e "   ${BLUE}${BOLD}≈ Performances similaires${NC}"
fi

# Détails des changements significatifs
echo ""
echo -e "${CYAN}${BOLD}📈 Changements significatifs:${NC}\n"

show_change() {
    local name=$1
    local percent=$2
    local abs=${percent#-}
    abs=${abs%.*}
    
    if [ "$percent" != "N/A" ] && [ $abs -gt 10 ]; then
        if (( $(echo "$percent > 0" | bc -l) )); then
            echo -e "   ${GREEN}↑${NC} $name: ${GREEN}+${percent}%${NC}"
        else
            echo -e "   ${YELLOW}↓${NC} $name: ${YELLOW}${percent}%${NC}"
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
