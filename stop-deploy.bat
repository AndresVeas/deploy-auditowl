@echo off
echo ========================================================
echo        Deteniendo Aplicacion Web y Base de Datos
echo ========================================================
echo.

cd /d "%~dp0"

echo Deteniendo contenedores de Tomcat y MariaDB...
docker compose down

echo.
echo ========================================================
echo Servicios detenidos con exito.
echo Nota: Los datos de la base de datos se conservan
echo en el volumen persistente (db_data).
echo ========================================================
echo.
pause
