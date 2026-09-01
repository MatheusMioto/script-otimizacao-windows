<#
.SYNOPSIS
    Módulo de logging para o script de otimização do Windows.
.DESCRIPTION
    Cria a estrutura de pastas por ano, mês e dia.
    Gera logs contendo data/hora, o que foi tentado e erros (se houverem).
#>

function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Acao,

        [Parameter(Mandatory=$true)]
        [string]$Modulo,
        
        [Parameter(Mandatory=$false)]
        [string]$Erro = "",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "ERROR", "WARNING", "SUCCESS")]
        [string]$Tipo = "INFO"
    )

    $DataAtual = Get-Date
    $Ano = $DataAtual.ToString("yyyy")
    $Mes = $DataAtual.ToString("MM")
    $Dia = $DataAtual.ToString("dd")
    $Timestamp = $DataAtual.ToString("dd/MM/yyyy HH:mm:ss")
    
    # Calcula a raiz do projeto baseada em onde este script está (scripts/logger.ps1)
    $BasePath = Split-Path -Parent $PSScriptRoot
    $LogDir = Join-Path $BasePath "logs\$Modulo\$Ano\$Mes\$Dia"
    
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    }
    
    $LogFile = Join-Path $LogDir "otimizacao.log"
    
    $LogEntry = "[$Timestamp] [$Tipo] $Acao"
    if ($Erro) {
        $LogEntry += " | DETALHE DO ERRO: $Erro"
    }
    
    Add-Content -Path $LogFile -Value $LogEntry
    
    # Saída no console para feedback visual
    if ($Tipo -eq "ERROR") {
        Write-Host $LogEntry -ForegroundColor Red
    } elseif ($Tipo -eq "WARNING") {
        Write-Host $LogEntry -ForegroundColor Yellow
    } elseif ($Tipo -eq "SUCCESS") {
        Write-Host $LogEntry -ForegroundColor Green
    } else {
        Write-Host $LogEntry -ForegroundColor Cyan
    }
}
