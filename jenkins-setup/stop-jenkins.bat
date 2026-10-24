@echo off
echo ========================================================
echo        Deteniendo Servidor Jenkins (CI/CD)
echo ========================================================
echo.

cd /d "%~dp0"

echo Deteniendo contenedores de Jenkins...
docker compose down

echo.
echo ========================================================
echo Servidor Jenkins detenido con exito.
echo Nota: Tus datos, usuarios y pipelines se conservan
echo en el volumen persistente (jenkins_data).
echo ========================================================
echo.
pause
