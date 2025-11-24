#!/bin/bash

# Générateur de rapport HTML pour les résultats de benchmark

RESULTS_DIR="$HOME/benchmark_results"
OUTPUT_DIR="$HOME/benchmark_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/report_${TIMESTAMP}.html"

mkdir -p "$OUTPUT_DIR"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║         Génération de Rapport HTML - Benchmark                ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# Vérifier les résultats disponibles
if [ ! -d "$RESULTS_DIR" ]; then
    echo -e "${YELLOW}Aucun résultat trouvé${NC}"
    exit 1
fi

# Lister les fichiers
files=($(ls -t "$RESULTS_DIR"/benchmark_*.txt 2>/dev/null))

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${YELLOW}Aucun résultat de benchmark trouvé${NC}"
    exit 1
fi

echo -e "${BLUE}Sélection du fichier à convertir :${NC}\n"

for i in "${!files[@]}"; do
    filename=$(basename "${files[$i]}")
    date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ /')
    printf "%2d. %s\n" $((i+1)) "$date"
done

echo ""
echo -n "Choisissez un fichier (1-${#files[@]}) ou 0 pour tous: "
read choice

if [ "$choice" = "0" ]; then
    # Générer un rapport pour tous les fichiers
    selected_files=("${files[@]}")
else
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#files[@]}" ]; then
        echo -e "${YELLOW}Choix invalide${NC}"
        exit 1
    fi
    selected_files=("${files[$((choice-1))]}")
fi

# Fonction pour extraire les données
extract_data() {
    local file=$1
    local component=$2
    grep "$component:" "$file" | grep -oP '\d+\.\d+' | head -1
}

# Générer le HTML
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Benchmark - Linux System</title>
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
EOF

# Pour chaque fichier sélectionné
for file in "${selected_files[@]}"; do
    filename=$(basename "$file")
    bench_date=$(echo "$filename" | sed 's/benchmark_//' | sed 's/.txt//' | sed 's/_/ /')
    
    # Extraire les données
    cpu_score=$(extract_data "$file" "CPU")
    ram_score=$(extract_data "$file" "RAM")
    disk_score=$(extract_data "$file" "Disque")
    gpu_score=$(extract_data "$file" "GPU")
    final_score=$(extract_data "$file" "SCORE FINAL")
    
    # Extraire les infos système
    cpu_model=$(grep "CPU:" "$file" | head -1 | cut -d':' -f2 | xargs)
    ram_total=$(grep "RAM:" "$file" | cut -d':' -f2 | xargs)
    gpu_info=$(grep "GPU:" "$file" | cut -d':' -f2 | xargs)
    
    # Déterminer la catégorie
    if (( $(echo "$final_score >= 80" | bc -l) )); then
        category="excellent"
        category_text="🏆 EXCELLENT"
    elif (( $(echo "$final_score >= 60" | bc -l) )); then
        category="good"
        category_text="✨ BON"
    elif (( $(echo "$final_score >= 40" | bc -l) )); then
        category="average"
        category_text="👍 MOYEN"
    else
        category="low"
        category_text="⚠️ FAIBLE"
    fi
    
    # Ajouter au HTML
    cat >> "$OUTPUT_FILE" << BENCHMARK_HTML
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
                        <div class="score-value">${cpu_score}</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>💾 RAM</h3>
                        <div class="score-value">${ram_score}</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>💿 Disque</h3>
                        <div class="score-value">${disk_score}</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item">
                        <h3>🎮 GPU</h3>
                        <div class="score-value">${gpu_score}</div>
                        <div class="score-label">/100</div>
                    </div>
                    
                    <div class="score-item final-score">
                        <h3>Score Final</h3>
                        <div class="score-value">${final_score}</div>
                        <div class="score-label">/100</div>
                        <div class="category-badge ${category}">${category_text}</div>
                    </div>
                </div>
                
                <div class="chart-container">
                    <canvas id="chart_${bench_date//:/_}"></canvas>
                </div>
                
                <script>
                    const ctx_${bench_date//:/_} = document.getElementById('chart_${bench_date//:/_}').getContext('2d');
                    new Chart(ctx_${bench_date//:/_}, {
                        type: 'radar',
                        data: {
                            labels: ['CPU', 'RAM', 'Disque', 'GPU'],
                            datasets: [{
                                label: 'Scores',
                                data: [${cpu_score}, ${ram_score}, ${disk_score}, ${gpu_score}],
                                fill: true,
                                backgroundColor: 'rgba(102, 126, 234, 0.2)',
                                borderColor: 'rgb(102, 126, 234)',
                                pointBackgroundColor: 'rgb(102, 126, 234)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'rgb(102, 126, 234)'
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
                                    suggestedMax: 100
                                }
                            }
                        }
                    });
                </script>
            </div>
BENCHMARK_HTML
done

# Fermer le HTML
cat >> "$OUTPUT_FILE" << 'EOF'
        </div>
        
        <footer>
            <p><strong>System Benchmark Tool v1.0</strong></p>
            <p class="timestamp">Rapport généré le $(date '+%d/%m/%Y à %H:%M:%S')</p>
        </footer>
    </div>
</body>
</html>
EOF

echo ""
echo -e "${GREEN}✓ Rapport HTML généré avec succès !${NC}"
echo ""
echo -e "${BLUE}Fichier de sortie :${NC} $OUTPUT_FILE"
echo ""
echo -e "${CYAN}Pour ouvrir le rapport :${NC}"
echo "  xdg-open $OUTPUT_FILE"
echo "  ou"
echo "  firefox $OUTPUT_FILE"
echo ""
