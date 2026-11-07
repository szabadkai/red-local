@echo off
cd /d "%~dp0"
where node >nul 2>nul
if not errorlevel 1 (
 node tools\serve.mjs --open
 exit /b
)
where py >nul 2>nul
if not errorlevel 1 (
 py -3 tools\serve.py
 exit /b
)
echo Install Node.js or Python 3 to run this local web game.
pause
