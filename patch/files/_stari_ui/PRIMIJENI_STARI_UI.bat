@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stari_ui.ps1" primijeni
if errorlevel 1 pause
