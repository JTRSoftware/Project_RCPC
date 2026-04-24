@echo off
title Connect ADB Wi-Fi

:: Habilitar ANSI (carácter ESC)
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

:: Definir cores
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "CYAN=%ESC%[36m"
set "RESET=%ESC%[0m"

:: /!\ Don't forget to set\correct this path \|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|\|/|\|
::          |                               |
set "ADB_DIR=C:\AndroidDK\SDK\platform-tools"
cd /d "%ADB_DIR%"

:inicio
cls
echo ==========================================
echo          ADB WIRELESS CONNECT
echo ==========================================
echo.
set /p "IP=> IP: "

:porta
echo.
set /p "PORT=> Port: "
set "ENDPOINT=%IP%:%PORT%"

:conectar
echo.
echo [Attempting to connect a %ENDPOINT%...]

:: Capturar resposta do ADB
for /f "delims=" %%r in ('adb connect %ENDPOINT%') do set "ADBMSG=%%r"

:: Escolher cor conforme a resposta
set "COR=%CYAN%"  :: padrão

echo %ADBMSG% | find "connected" >nul && set "COR=%GREEN%"
echo %ADBMSG% | find "already connected" >nul && set "COR=%YELLOW%"
echo %ADBMSG% | find "failed" >nul && set "COR=%RED%"
echo %ADBMSG% | find "unable" >nul && set "COR=%RED%"
echo %ADBMSG% | find "no devices" >nul && set "COR=%RED%"
echo %ADBMSG% | find "cannot" >nul && set "COR=%RED%"
echo %ADBMSG% | find "error" >nul && set "COR=%RED%"

:: Mostrar resposta colorida
echo %COR%%ADBMSG%%RESET%

echo.
echo ------------------------------------------
echo Options:
echo [P] Correct Port
echo [I] Correct IP and Port
echo [E] Exit
echo.

choice /C PIE /N /M "Choose: "

IF ERRORLEVEL 3 GOTO fim
IF ERRORLEVEL 2 GOTO inicio
IF ERRORLEVEL 1 GOTO porta

:fim
echo.
echo I'm Out...
timeout /t 1 >nul
