#!/bin/bash
set -e

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE}        Iniciando Servidor Jenkins (CI/CD)              ${NC}"
echo -e "${BLUE}========================================================${NC}"

echo -e "\n${GREEN}[1/3] Levantando contenedor de Jenkins...${NC}"
docker compose up -d

echo -e "\n${GREEN}[2/3] Esperando que Jenkins inicialice los servicios...${NC}"
MAX_RETRIES=30
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    if docker exec jenkins-server test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
        PASS=$(docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword)
        echo -e "\n${GREEN}[3/3] Obteniendo clave inicial de administrador...${NC}"
        echo -e "${BLUE}========================================================${NC}"
        echo -e " CLAVE INICIAL DE JENKINS:"
        echo -e " ${GREEN}${PASS}${NC}"
        echo -e "${BLUE}========================================================${NC}"
        echo -e " Accede a Jenkins en: ${GREEN}http://localhost:8081${NC}"
        echo -e " Pega la clave indicada arriba para iniciar la configuracion."
        echo -e "${BLUE}========================================================${NC}"
        exit 0
    elif docker exec jenkins-server test -f /var/jenkins_home/config.xml 2>/dev/null; then
        echo -e "\n${GREEN}[3/3] Jenkins ya se encuentra configurado previamente.${NC}"
        echo -e "${BLUE}========================================================${NC}"
        echo -e " No se requiere clave temporal."
        echo -e " Inicia sesión con tu usuario y contraseña en: ${GREEN}http://localhost:8081${NC}"
        echo -e "${BLUE}========================================================${NC}"
        exit 0
    fi
    sleep 2
    COUNT=$((COUNT + 1))
done

echo -e "\n${YELLOW}[ADVERTENCIA] Jenkins está tardando en responder. Revisa los logs con: docker logs jenkins-server${NC}"
