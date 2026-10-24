#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE}        Deteniendo Aplicación Web y Base de Datos       ${NC}"
echo -e "${BLUE}========================================================${NC}"

echo -e "\n${GREEN}Deteniendo contenedores de Tomcat y MariaDB...${NC}"
docker compose down

echo -e "\n${BLUE}========================================================${NC}"
echo -e "${GREEN}Servicios detenidos con éxito.${NC}"
echo -e "Nota: Los datos de la base de datos se conservan"
echo -e "en el volumen persistente (db_data)."
echo -e "${BLUE}========================================================${NC}"
