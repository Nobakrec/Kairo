@echo off
rem Saves every change in this folder to GitHub, on the branch you're on.
cd /d "%~dp0"
git add -A
git commit -m "Update Kairo"
git push
pause
