@echo off
:: ==============================================================================
:: Lançador Executável com Elevação Automática (UAC)
:: ==============================================================================
title Otimizador do Windows

:: Checa privilégios de Administrador e solicita UAC se necessário
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando privilégios de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo ========================================================
echo  INICIANDO OTIMIZADOR DO WINDOWS
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Otimizar-Windows-Monolito.ps1"

pause
