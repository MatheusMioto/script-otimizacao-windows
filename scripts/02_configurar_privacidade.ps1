<#
.SYNOPSIS
    Script responsável por ajustes de políticas de usuário e privacidade.
.DESCRIPTION
    Aplica alterações em chaves de registro (Registry) e GPOs (Group Policy Objects)
    para desabilitar telemetria, Cortana e rastreadores do sistema operacional.
#>

# Importa o módulo de log
. "$PSScriptRoot\logger.ps1"

Write-Log -Modulo "Privacidade" -Acao "Iniciando módulo de políticas e privacidade" -Tipo "INFO"

try {
    # Função auxiliar para criar/alterar chaves de registro de forma segura
    function Set-RegistryKey {
        param(
            [string]$Path, 
            [string]$Name, 
            [int]$Value, 
            [string]$Type="DWord"
        )
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
        Write-Log -Modulo "Privacidade" -Acao "RegKey definida: $Path\$Name = $Value" -Tipo "INFO"
    }

    Write-Log -Modulo "Privacidade" -Acao "Aplicando políticas de Telemetria..." -Tipo "INFO"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "MaxTelemetryAllowed" -Value 1

    Write-Log -Modulo "Privacidade" -Acao "Aplicando políticas de Advertising ID (Rastreador)..." -Tipo "INFO"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

    Write-Log -Modulo "Privacidade" -Acao "Desabilitando features de consumidor e nuvem (impede download de bloatwares)..." -Tipo "INFO"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

    Write-Log -Modulo "Privacidade" -Acao "Desativando anúncios e sugestões do Menu Iniciar e Tela de Bloqueio..." -Tipo "INFO"
    $cdmPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $cdmKeys = @(
        "FeatureManagementEnabled",
        "OemPreInstalledAppsEnabled",
        "PreInstalledAppsEnabled",
        "SilentInstalledAppsEnabled",
        "SoftLandingEnabled",
        "SystemPaneSuggestionsEnabled",
        "SubscribedContent-310093Enabled",
        "SubscribedContent-338387Enabled",
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-338393Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled",
        "SubscribedContent-353698Enabled"
    )
    foreach ($key in $cdmKeys) {
        Set-RegistryKey -Path $cdmPath -Name $key -Value 0
    }

    Write-Log -Modulo "Privacidade" -Acao "Módulo de políticas finalizado com sucesso." -Tipo "SUCCESS"
} catch {
    Write-Log -Modulo "Privacidade" -Acao "Falha durante execução do módulo de políticas." -Erro $_.Exception.Message -Tipo "ERROR"
}
