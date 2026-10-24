@echo off
echo ===========================================
echo     Iniciando Despliegue del Sistema       
echo ===========================================

echo.
echo [1/3] Descargando imagenes mas recientes (App y MariaDB)...
docker compose pull

echo.
echo [2/3] Levantando MariaDB y Tomcat...
docker compose up -d

echo.
echo [3/3] Verificando estado de los servicios...
docker compose ps

echo.
echo ===========================================
echo Despliegue completado!
echo Aplicacion Web (Tomcat): http://localhost:8080
echo Base de datos (MariaDB): localhost:3306 (DB: owl_auditv1)
echo ===========================================
