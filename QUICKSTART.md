# 🚀 Guide de Démarrage Rapide

## Installation en 2 étapes

### 1. Installer les dépendances
```bash
./install.sh
```

### 2. Lancer le benchmark
```bash
./system_benchmark.sh
```

C'est tout ! Les résultats seront dans `~/benchmark_results/`

---

## 📂 Structure des Fichiers

```
system_benchmark/
├── install.sh                    # Installation automatique
├── system_benchmark.sh          # Script principal de benchmark
├── compare_benchmarks.sh        # Comparer plusieurs résultats
├── generate_html_report.sh      # Générer un rapport HTML visuel
└── README.md                    # Documentation complète
```

---

## ⚡ Utilisation Rapide

### Lancer un benchmark
```bash
./system_benchmark.sh
```
⏱️ Durée: 5-10 minutes

### Comparer deux benchmarks
```bash
./compare_benchmarks.sh
```
Sélectionnez deux dates à comparer et obtenez une analyse détaillée.

### Générer un rapport HTML
```bash
./generate_html_report.sh
```
Créez un rapport visuel avec graphiques dans votre navigateur.

---

## 📊 Exemple de Score

```
╔════════════════════════════════════════╗
║         SCORES DÉTAILLÉS               ║
╠════════════════════════════════════════╣
║ CPU:        72.35/100 (35%)            ║
║ RAM:        65.20/100 (20%)            ║
║ Disque:     88.50/100 (30%)            ║
║ GPU:        70.15/100 (15%)            ║
╠════════════════════════════════════════╣
║ SCORE FINAL: 75.43/100                 ║
╚════════════════════════════════════════╝

Catégorie: ✨ BON - PC performant
```

---

## 🎯 Composants Testés

| Composant | Test | Référence |
|-----------|------|-----------|
| 🖥️ **CPU** | Single + Multi-thread | CPU 8 cores moderne |
| 💾 **RAM** | Vitesse lecture/écriture | DDR4-3200 |
| 💿 **Disque** | Sequential + IOPS 4K | NVMe Gen4 |
| 🎮 **GPU** | Rendu OpenGL | GPU milieu de gamme |

---

## 🔍 Interprétation Rapide

| Score | Signification |
|-------|---------------|
| **80-100** | 🏆 Excellent - Gaming/Workstation haut de gamme |
| **60-79** | ✨ Bon - Gaming/Travail standard |
| **40-59** | 👍 Moyen - Bureautique/Multimédia |
| **0-39** | ⚠️ Faible - Ancien matériel |

---

## 💡 Conseils

### Avant de benchmarker
- Fermez les applications lourdes
- Branchez votre laptop sur secteur
- Assurez-vous d'avoir 5GB d'espace libre

### Pour des résultats fiables
- Lancez 2-3 benchmarks et faites une moyenne
- Ne comparez que des benchmarks dans les mêmes conditions
- Les températures élevées peuvent affecter les scores

---

## 🐛 Problèmes Courants

### "Display not found"
```bash
# Solution 1: Installer X11 virtuel
sudo apt install xvfb
xvfb-run ./system_benchmark.sh

# Solution 2: Le test GPU sera ignoré (score par défaut = 50)
```

### "Permission denied"
```bash
chmod +x *.sh
```

### "Package not found"
```bash
./install.sh  # Réinstaller les dépendances
```

---

## 📈 Améliorations Possibles

Votre score ne vous satisfait pas ? Voici les upgrades les plus efficaces par ordre d'impact :

1. **SSD NVMe** → Impact disque (+30-50 points)
2. **RAM plus rapide** → Impact RAM (+10-20 points)
3. **CPU moderne** → Impact CPU (+20-40 points)
4. **GPU dédié** → Impact GPU (+30-50 points)

---

## 📞 Support

- 🐛 Bugs : Créez une issue sur GitHub
- 📖 Docs : Lisez le README.md complet
- 💬 Questions : Vérifiez d'abord la doc

---

## ⭐ Bonus

### Automatiser les benchmarks hebdomadaires
```bash
# Ajouter au crontab
crontab -e

# Lancer chaque dimanche à 2h du matin
0 2 * * 0 /path/to/system_benchmark.sh
```

### Export vers CSV
```bash
# Extraire tous les scores dans un CSV
grep "SCORE FINAL" ~/benchmark_results/*.txt | \
  sed 's/.*benchmark_//' | sed 's/.txt:/ /' | \
  sed 's/SCORE FINAL: //' > scores.csv
```

---

**Prêt à benchmarker ? Lancez `./system_benchmark.sh` ! 🚀**
