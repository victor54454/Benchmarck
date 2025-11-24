#!/bin/bash

# Script d'installation automatique pour System Benchmark Tool

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Installation - System Benchmark Tool     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Détection de la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Impossible de détecter la distribution${NC}"
    exit 1
fi

echo -e "${GREEN}Distribution détectée: $PRETTY_NAME${NC}"
echo ""

# Installation selon la distribution
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
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Installation terminée avec succès !${NC}"
echo ""
echo -e "${BLUE}Vous pouvez maintenant lancer le benchmark avec :${NC}"
echo -e "  ${YELLOW}./system_benchmark.sh${NC}"
echo ""
