@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0baixar-iso.ps1" %*
pause
