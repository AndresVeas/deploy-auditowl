#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE}        Deteniendo Servidor Jenkins (CI/CD)             ${NC}"
echo -e "${BLUE}========================================================${NC}"

echo -e "\n${GREEN}Deteniendo contenedores de Jenkins...${NC}"
docker compose down

echo -e "\n${BLUE}========================================================${NC}"
echo -e "${GREEN}Servidor Jenkins detenido con éxito.${NC}"
echo -e "Nota: Tus datos, usuarios y pipelines se conservan"
echo -e "en el volumen persistente (jenkins_data)."
echo -e "${BLUE}========================================================${NC}"
