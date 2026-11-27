@echo off
rem Makes Kairo's installer; see make-installer.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-installer.ps1"
pause
