# Atalho dev local - Painel BI
# Uso: powershell -ExecutionPolicy Bypass -File .\iniciar-dev.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location $PSScriptRoot
npm.cmd run dev -- --webpack -p 3001 -H 127.0.0.1
