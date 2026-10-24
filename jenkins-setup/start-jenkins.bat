@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo        Iniciando Servidor Jenkins (CI/CD)
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Levantando contenedor de Jenkins...
docker compose up -d

echo.
echo [2/3] Esperando que Jenkins inicialice los servicios...
set MAX_RETRIES=30
set COUNT=0

:WAIT_LOOP
set /a COUNT+=1
if !COUNT! gtr !MAX_RETRIES! (
    echo.
    echo [ADVERTENCIA] Jenkins esta tardando en arrancar. 
    echo Revisa el estado manualmente con: docker logs jenkins-server
    goto :FIN
)

docker exec jenkins-server test -f /var/jenkins_home/secrets/initialAdminPassword >nul 2>&1
if !errorlevel! equ 0 (
    goto :FOUND_PASS
)

docker exec jenkins-server test -f /var/jenkins_home/config.xml >nul 2>&1
if !errorlevel! equ 0 (
    docker exec jenkins-server test -f /var/jenkins_home/secrets/initialAdminPassword >nul 2>&1
    if !errorlevel! neq 0 (
        goto :ALREADY_CONFIGURED
    )
)

timeout /t 2 /nobreak >nul
goto :WAIT_LOOP

:FOUND_PASS
echo.
echo [3/3] Obteniendo clave inicial de administrador...
echo ========================================================
echo  CLAVE INICIAL DE JENKINS:
for /f "delims=" %%i in ('docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword') do echo  %%i
echo ========================================================
echo.
echo  Accede a Jenkins en: http://localhost:8081
echo  Pega la clave indicada arriba para iniciar la configuracion.
echo ========================================================
goto :FIN

:ALREADY_CONFIGURED
echo.
echo [3/3] Jenkins ya se encuentra configurado previamente.
echo ========================================================
echo  No se requiere clave temporal.
echo  Inicia sesion con tu usuario y contrasena habitual en:
echo  http://localhost:8081
echo ========================================================

:FIN
echo.
pause
