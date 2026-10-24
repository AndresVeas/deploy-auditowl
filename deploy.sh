#!/bin/bash
set -e

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}    Iniciando Despliegue del Sistema       ${NC}"
echo -e "${BLUE}===========================================${NC}"

echo -e "\n${GREEN}[1/3] Descargando imágenes más recientes (App y MariaDB)...${NC}"
docker compose pull || echo "Advertencia: No se pudo hacer pull remoto, usando imágenes locales existentes si están disponibles."

echo -e "\n${GREEN}[2/3] Levantando MariaDB y Tomcat...${NC}"
docker compose up -d

echo -e "\n${GREEN}[3/3] Verificando estado de los servicios...${NC}"
docker compose ps

echo -e "\n${BLUE}===========================================${NC}"
echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "Aplicación Web (Tomcat): ${GREEN}http://localhost:8080${NC}"
echo -e "Base de datos (MariaDB): ${GREEN}localhost:3306 (DB: owl_auditv1)${NC}"
echo -e "${BLUE}===========================================${NC}"
