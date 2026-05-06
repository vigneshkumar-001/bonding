@echo off
setlocal
REM Convenience wrapper so you can just run: run
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1"
endlocal

