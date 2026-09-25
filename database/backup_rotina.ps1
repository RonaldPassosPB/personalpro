# ==============================================================================
# Rotina de Backup Automático Diário do Banco de Dados - PersonalPro SaaS
# ==============================================================================

param(
    [string]$Server = "localhost",
    [string]$Database = "PersonalPro",
    [string]$User = "sa",
    [string]$Password = "Soore1020.",
    [int]$RetencaoDias = 15
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$backupDir = Join-Path $scriptDir "backups"

if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}
& icacls $backupDir /grant "*S-1-1-0:(OI)(CI)F" /T /Q | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$dataHoje = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$arquivoBackup = Join-Path $backupDir "${Database}_Backup_${timestamp}.bak"
$arquivoLog = Join-Path $backupDir "backup_history.log"

Write-Host "[$dataHoje] Iniciando backup do banco '$Database'..." -ForegroundColor Cyan

try {
    $sql = "BACKUP DATABASE [$Database] TO DISK = N'$arquivoBackup' WITH COMPRESSION, INIT, STATS = 10;"
    
    $output = & sqlcmd -S $Server -U $User -P $Password -Q $sql 2>&1
    
    if (Test-Path $arquivoBackup) {
        $tamanhoBytes = (Get-Item $arquivoBackup).Length
        $tamanhoMB = [math]::Round($tamanhoBytes / 1MB, 2)
        
        $msgSucesso = "[$dataHoje] SUCESSO: Backup gerado em '$arquivoBackup' ($tamanhoMB MB)."
        Write-Host $msgSucesso -ForegroundColor Green
        Add-Content -Path $arquivoLog -Value $msgSucesso
        
        # Limpeza de backups antigos (retenção de 15 dias)
        $limiteData = (Get-Date).AddDays(-$RetencaoDias)
        $antigos = Get-ChildItem -Path $backupDir -Filter "${Database}_Backup_*.bak" | Where-Object { $_.CreationTime -lt $limiteData }
        
        foreach ($arq in $antigos) {
            Remove-Item $arq.FullName -Force
            $msgRemovido = "[$dataHoje] LIMPEZA: Backup antigo removido: $($arq.Name)"
            Write-Host $msgRemovido -ForegroundColor Yellow
            Add-Content -Path $arquivoLog -Value $msgRemovido
        }
    } else {
        throw "Arquivo de backup não foi encontrado após o comando: $output"
    }
} catch {
    $msgErro = "[$dataHoje] ERRO no backup: $_"
    Write-Host $msgErro -ForegroundColor Red
    Add-Content -Path $arquivoLog -Value $msgErro
    exit 1
}
