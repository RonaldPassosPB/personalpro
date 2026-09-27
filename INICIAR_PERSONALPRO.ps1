# ==============================================================================
# PERSONALPRO SAAS — SCRIPT DE INICIALIZAÇÃO 1-CLIQUE (COM CODIFICAÇÃO UTF-8)
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "🚀 INICIANDO SISTEMA PERSONALPRO SAAS (MULTI-TENANT)..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$apiProj = Join-Path $root "PersonalProAPI\PersonalProAPI.csproj"

Start-Process powershell -ArgumentList "-NoExit", "-Command", "dotnet run --project '$apiProj'"
Start-Sleep -Seconds 4
Start-Process "http://localhost:5255/?v=6"
