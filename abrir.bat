@echo off
set "SCRIPT=%~dp0kiosk-lock.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
