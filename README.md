# 🚀 System Benchmark Tool - Linux

Outil de benchmark complet et fiable pour tester les performances de votre PC Linux.

## 📋 Pré-requis

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y sysbench fio mesa-utils jq bc
```

### Fedora/RHEL/CentOS
```bash
sudo dnf install -y sysbench fio mesa-demos jq bc
```

### Arch Linux
```bash
sudo pacman -S sysbench fio mesa-utils jq bc
```

## 🎯 Utilisation

### Lancement simple
```bash
./system_benchmark.sh
```

Le script va :
1. Vérifier que toutes les dépendances sont installées
2. Afficher les infos système
3. Lancer les tests (environ 5-10 minutes)
4. Calculer un score final sur 100
5. Sauvegarder les résultats dans `~/benchmark_results/`

## 📊 Tests réalisés

### 🖥️ CPU (Score pondéré : 35%)
- **Single-thread** : Calcul de nombres premiers (1 thread)
- **Multi-thread** : Calcul parallèle (tous les threads)
- **Outils** : sysbench CPU benchmark
- **Référence** : 2000 events/sec (single), 16000 events/sec (multi)

### 💾 RAM (Score pondéré : 20%)
- **Vitesse d'écriture** : Écriture séquentielle en mémoire
- **Vitesse de lecture** : Lecture séquentielle
- **Outils** : sysbench memory benchmark
- **Référence** : 10000 MiB/s (DDR4-3200)

### 💿 Disque (Score pondéré : 30%)
- **Lecture/Écriture séquentielle** : Blocs de 1MB
- **IOPS aléatoires** : Blocs de 4K (lecture/écriture mixte)
- **Outils** : fio (Flexible I/O Tester)
- **Référence** : 3000 MB/s seq, 50000 IOPS (NVMe)

### 🎮 GPU (Score pondéré : 15%)
- **Rendu OpenGL** : Test de FPS avec glxgears
- **Outils** : mesa-utils (glxgears)
- **Référence** : 2000 FPS

## 📈 Interprétation des scores

| Score | Catégorie | Description |
|-------|-----------|-------------|
| 80-100 | 🏆 EXCELLENT | PC très performant (gaming/workstation haut de gamme) |
| 60-79 | ✨ BON | PC performant (gaming/travail standard) |
| 40-59 | 👍 MOYEN | PC standard (bureautique/multimédia) |
| 0-39 | ⚠️ FAIBLE | PC limité (ancien matériel) |

## 📁 Résultats

Les résultats sont sauvegardés dans : `~/benchmark_results/benchmark_YYYYMMDD_HHMMSS.txt`

Exemple de visualisation :
```bash
# Voir tous les benchmarks
ls -lh ~/benchmark_results/

# Voir le dernier résultat
cat ~/benchmark_results/benchmark_*.txt | tail -50

# Comparer deux résultats
diff ~/benchmark_results/benchmark_20240101_120000.txt \
     ~/benchmark_results/benchmark_20240201_120000.txt
```

## 🔧 Options avancées

### Exécution sans interaction
```bash
yes "" | ./system_benchmark.sh
```

### Benchmark spécifique (modifications dans le script)
Vous pouvez modifier les durées de test dans le script :
- `--runtime=30` : Durée des tests fio
- `--threads=$CPU_THREADS` : Nombre de threads CPU
- `sleep 10` : Durée du test GPU

## 🎓 Comprendre les résultats

### Exemples de configurations typiques

**PC Gaming haut de gamme (Score ~85-95)**
- CPU: Ryzen 9 7950X / Intel i9-13900K
- RAM: 32GB DDR5-6000
- Disque: NVMe Gen4 (Samsung 980 Pro)
- GPU: RTX 4080 / RX 7900 XT

**PC Gamer milieu de gamme (Score ~65-75)**
- CPU: Ryzen 5 7600X / Intel i5-13600K
- RAM: 16GB DDR4-3200
- Disque: NVMe Gen3 (WD Black SN750)
- GPU: RTX 4060 / RX 7600

**PC Bureautique (Score ~45-55)**
- CPU: Intel i3 / Ryzen 3
- RAM: 8GB DDR4-2666
- Disque: SATA SSD
- GPU: Intégré

**Ancien PC (Score ~25-35)**
- CPU: Intel Core 2 Duo / Athlon II
- RAM: 4GB DDR3
- Disque: HDD 7200RPM
- GPU: Intégré ancien

## 🛠️ Dépannage

### Erreur "Display not found"
Le test GPU nécessite un serveur X11. Sur un serveur sans interface graphique :
- Le script continuera avec GPU_SCORE=50
- Ou installez X11 virtuel : `sudo apt install xvfb`
- Lancez : `xvfb-run ./system_benchmark.sh`

### Erreur "Permission denied" sur /tmp
```bash
# Vérifier les permissions
ls -ld /tmp
# Doit afficher : drwxrwxrwt
```

### Benchmark disque très lent
- Vérifiez l'espace disponible : `df -h ~`
- Le test crée ~2GB de fichiers temporaires

## 📝 Notes importantes

- **Performances réalistes** : Les références sont basées sur du matériel réel de 2023-2024
- **Tests non destructifs** : Aucune modification permanente du système
- **Reproductibilité** : Fermez les applications gourmandes avant le test
- **Sécurité** : Le script ne nécessite pas de droits root

## 🔬 Méthodologie technique

### Pourquoi ces outils ?

- **sysbench** : Standard industrie, utilisé par MySQL, Percona
- **fio** : Outil de référence pour I/O (utilisé par Intel, Samsung)
- **glxgears** : Simple mais efficace pour test OpenGL basique
- **jq/bc** : Parsing et calculs fiables

### Validité des scores

Les références sont basées sur :
- Benchmarks publics (PassMark, UserBenchmark)
- Spécifications constructeurs
- Tests réels sur matériel varié

## 🤝 Contribution

Ce script est open-source. Améliorations suggérées :
- Support de benchmark GPU avancé (vulkan, glmark2)
- Test réseau (iperf3)
- Comparaison avec base de données en ligne
- Support de monitoring temps réel

## 📜 Licence

MIT License - Utilisation libre

## 🔗 Ressources

- [sysbench documentation](https://github.com/akopytov/sysbench)
- [fio documentation](https://fio.readthedocs.io/)
- [Linux Performance](http://www.brendangregg.com/linuxperf.html)
