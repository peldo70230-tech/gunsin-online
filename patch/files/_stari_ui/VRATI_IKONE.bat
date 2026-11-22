@echo off
cd /d "%~dp0..\data\HyperText"
if not exist "_ikone_original" (echo Nema foldera _ikone_original & pause & exit /b)
copy /Y "_ikone_original\*.*" "." >nul
echo Ikone su vracene na original.
pause
