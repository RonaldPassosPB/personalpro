# ==============================================================================
# Agendador de Backup Diário no Windows Task Scheduler - PersonalPro SaaS
# Executa todos os dias às 03:00 da manhã
# ==============================================================================

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptBackup = Join-Path $scriptDir "backup_rotina.ps1"
$nomeTarefa = "PersonalPro_SQLBackup_Diario"

Write-Host "Configurando tarefa agendada '$nomeTarefa' no Windows..." -ForegroundColor Cyan

$acao = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptBackup`""
$gatilho = New-ScheduledTaskTrigger -Daily -At 3:00AM
$config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $nomeTarefa -Action $acao -Trigger $gatilho -Settings $config -Description "Backup diário automático do banco SQL Server PersonalPro SaaS" -Force | Out-Null

Write-Host "✅ Tarefa '$nomeTarefa' agendada com sucesso para todos os dias às 03:00 AM!" -ForegroundColor Green
