@echo off
setlocal

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Give admin so i can change the mac carefully!!!
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)


cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mac_changer.ps1"

:: Get out after finishing (because why should i stay on background like a virus?)
exit
