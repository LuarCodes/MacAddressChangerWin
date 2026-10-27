@echo off
setlocal

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Give admin so i can fucking change mac nigga
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)


cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mac_changer.ps1"

:: Get the fuck out after finishing
exit