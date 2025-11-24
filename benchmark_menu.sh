#!/bin/bash

# Menu interactif principal pour BenchmarkPro

# Couleurs
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

# Obtenir le chemin du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fonction pour afficher le menu
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
    ║                              v2.0                                     ║
    ╚═══════════════════════════════════════════════════════════════════════╝
MENU_EOF
    echo -e "${NC}\n"
    
    # Afficher les derniers résultats si disponibles
    if [ -d "$SCRIPT_DIR/results" ]; then
        local latest=$(ls -t "$SCRIPT_DIR/results"/benchmark_*.txt 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            local score=$(grep "SCORE FINAL:" "$latest" | awk '{print $3}' | cut -d'/' -f1)
            local date=$(basename "$latest" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
            
            if [ -n "$score" ]; then
                local int_score=${score%.*}
                local color=$RED
                if [ $int_score -gt 70 ]; then color=$GREEN; elif [ $int_score -gt 40 ]; then color=$YELLOW; fi
                
                echo -e "${DIM}   Dernier benchmark: ${date}${NC}"
                echo -e "${DIM}   Score: ${color}${BOLD}${score}${NC}${DIM}/100${NC}\n"
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
    echo -e "${CYAN}${BOLD}║${NC}  ${RED}${BOLD}0.${NC} ❌ ${WHITE}Quitter${NC}                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                                                               ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction pour afficher les résultats
show_results() {
    clear
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                   ${WHITE}${BOLD}HISTORIQUE DES BENCHMARKS${NC}                  ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"
    
    if [ ! -d "$SCRIPT_DIR/results" ]; then
        echo -e "${YELLOW}Aucun résultat trouvé${NC}\n"
        return
    fi
    
    local files=($(ls -t "$SCRIPT_DIR/results"/benchmark_*.txt 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Aucun benchmark effectué${NC}\n"
        return
    fi
    
    echo -e "${WHITE}${BOLD}Total: ${#files[@]} benchmark(s)${NC}\n"
    
    for file in "${files[@]}"; do
        local filename=$(basename "$file")
        local date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ - /')
        local score=$(grep "SCORE FINAL:" "$file" | awk '{print $3}' | cut -d'/' -f1 2>/dev/null)
        
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
            echo -e "   Score: ${color}${BOLD}${score}${NC}/100"
            
            # Mini détails
            local cpu=$(grep "^CPU:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local ram=$(grep "^RAM:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local disk=$(grep "^Disque:" "$file" | grep -oP '\d+\.\d+' | head -1)
            local gpu=$(grep "^GPU:" "$file" | grep -oP '\d+\.\d+' | head -1)
            
            echo -e "   ${DIM}CPU: ${cpu} │ RAM: ${ram} │ Disque: ${disk} │ GPU: ${gpu}${NC}"
            echo ""
        fi
    done
}

# Fonction pour afficher le guide
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
    
    echo -e "${DIM}Pour plus de détails, consultez: guide_optimisation.md${NC}\n"
}

# Pause
pause() {
    echo ""
    echo -ne "${DIM}Appuyez sur [ENTRÉE] pour continuer...${NC}"
    read
}

# Main
main() {
    while true; do
        show_menu
        echo -ne "${CYAN}${BOLD}Votre choix → ${NC}"
        read choice
        
        case $choice in
            1)
                echo ""
                if [ -f "$SCRIPT_DIR/system_benchmark_v2_corrected.sh" ]; then
                    "$SCRIPT_DIR/system_benchmark_v2_corrected.sh"
                else
                    echo -e "${RED}Erreur: system_benchmark_v2_corrected.sh introuvable${NC}"
                fi
                pause
                ;;
            2)
                echo ""
                if [ -f "$SCRIPT_DIR/compare_benchmarks_v2_corrected.sh" ]; then
                    "$SCRIPT_DIR/compare_benchmarks_v2_corrected.sh"
                else
                    echo -e "${RED}Erreur: compare_benchmarks_v2_corrected.sh introuvable${NC}"
                fi
                pause
                ;;
            3)
                echo ""
                if [ -f "$SCRIPT_DIR/generate_html_report_v2_corrected.sh" ]; then
                    "$SCRIPT_DIR/generate_html_report_v2_corrected.sh"
                else
                    echo -e "${RED}Erreur: generate_html_report_v2_corrected.sh introuvable${NC}"
                fi
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
            0)
                clear
                echo -e "\n${CYAN}${BOLD}👋 Merci d'avoir utilisé BenchmarkPro !${NC}\n"
                echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}Résultats sauvegardés dans:${NC} ${WHITE}$SCRIPT_DIR/results/${NC}"
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

# Lancer
main