<#
.SYNOPSIS
    Script responsável pelas configurações e otimizações gerais do Windows.
.DESCRIPTION
    Ajusta serviços em segundo plano, planos de energia, efeitos visuais
    e realiza a limpeza de arquivos temporários para ganho de performance.
#>

# Importa o módulo de log
. "$PSScriptRoot\logger.ps1"

Write-Log -Modulo "ConfigGerais" -Acao "Iniciando módulo de configuração do Windows" -Tipo "INFO"

try {
    # 1. Limpeza Profunda
    Write-Log -Modulo "ConfigGerais" -Acao "Iniciando limpeza de arquivos temporários..." -Tipo "INFO"
    try {
        $tempDirs = @("$env:windir\Temp\*", "$env:LOCALAPPDATA\Temp\*")
        foreach ($dir in $tempDirs) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log -Modulo "ConfigGerais" -Acao "Limpeza de Temp e Lixeira concluída." -Tipo "SUCCESS"
    } catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Aviso não crítico durante limpeza." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    # 2. Plano de Energia
    Write-Log -Modulo "ConfigGerais" -Acao "Alterando plano de energia para Alto Desempenho..." -Tipo "INFO"
    try {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Log -Modulo "ConfigGerais" -Acao "Plano de energia alterado com sucesso." -Tipo "SUCCESS"
    } catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Falha ao alterar plano de energia." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    # 3. Otimização de Serviços
    Write-Log -Modulo "ConfigGerais" -Acao "Desativando serviços desnecessários (Telemetry, Fax, Maps)..." -Tipo "INFO"
    $servicesToDisable = @("DiagTrack", "dmwappushservice", "Fax", "MapsBroker")
    foreach ($svc in $servicesToDisable) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            try {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
                Write-Log -Modulo "ConfigGerais" -Acao "Serviço desativado permanentemente: $svc" -Tipo "SUCCESS"
            } catch {
                Write-Log -Modulo "ConfigGerais" -Acao "Não foi possível desativar o serviço: $svc" -Erro $_.Exception.Message -Tipo "WARNING"
            }
        }
    }

    # 4. Ajustes Visuais e de Performance
    Write-Log -Modulo "ConfigGerais" -Acao "Aplicando ajustes visuais via Registro (GameMode, Transparência)..." -Tipo "INFO"
    try {
        function Set-RegKeySafe {
            param([string]$Path, [string]$Name, $Value, [string]$Type="DWord")
            if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
        }

        # Game Mode (Ativar)
        Set-RegKeySafe -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
        
        # Desativar Transparência para poupar GPU
        Set-RegKeySafe -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
        
        # Desativar animações pesadas de janelas
        Set-RegKeySafe -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type "String"
        Set-RegKeySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0

        Write-Log -Modulo "ConfigGerais" -Acao "Ajustes de interface aplicados com sucesso." -Tipo "SUCCESS"
    } catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Falha ao aplicar ajustes de interface." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    Write-Log -Modulo "ConfigGerais" -Acao "Módulo de configurações gerais finalizado com sucesso." -Tipo "SUCCESS"
} catch {
    Write-Log -Modulo "ConfigGerais" -Acao "Falha durante execução do módulo de configurações gerais." -Erro $_.Exception.Message -Tipo "ERROR"
}
