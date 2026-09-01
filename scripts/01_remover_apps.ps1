<#
.SYNOPSIS
    Script responsável pela remoção de bloatwares e aplicativos nativos desnecessários.
.DESCRIPTION
    Este script contém funções e comandos para remover pacotes UWP/Appx
    pré-instalados no Windows que não são essenciais, melhorando o desempenho e 
    liberando espaço.
#>

# Importa o módulo de log
. "$PSScriptRoot\logger.ps1"

Write-Log -Modulo "RemoverApps" -Acao "Iniciando módulo de exclusão de apps" -Tipo "INFO"

try {
    # Lista de pacotes para remover
    $appsToRemove = @(
        # Especificados diretamente
        "Microsoft.MSPaint",
        "Microsoft.WindowsAlarms",
        "Microsoft.Getstarted",
        "Microsoft.GetHelp",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.BingFinance",
        "Microsoft.BingSports",
        "Microsoft.BingWeather",
        "Microsoft.BingNews",
        "Microsoft.ZuneVideo",
        "Microsoft.Paint3D",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.WindowsSoundRecorder",

        # Ecossistema Xbox
        "Microsoft.XboxApp",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.Xbox.TCUI",

        # Apps Modernos Nativos (exceto Teams)
        "Microsoft.549981C3F5F10", # Cortana
        "Clipchamp.Clipchamp",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.Todos",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.YourPhone",
        "Microsoft.People",
        "microsoft.windowscommunicationsapps",
        "Microsoft.OneConnect",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",

        # Bloatwares Patrocinados e de Terceiros
        "SpotifyAB.SpotifyMusic",
        "king.com.CandyCrushSaga",
        "king.com.CandyCrushSodaSaga",
        "king.com.CandyCrushFriends",
        "NetflixO.Netflix",
        "ROBLOXCORPORATION.ROBLOX",
        "Facebook.317180B0BB486",
        "A278AB0D.DisneyMagicKingdoms",
        "DolbyLaboratories.DolbyAccess",
        "Amazon.com.Amazon",
        "TikTok",
        "TencentVideo"
    )

    Write-Log -Modulo "RemoverApps" -Acao "Iniciando varredura e remoção de $($appsToRemove.Count) aplicativos..." -Tipo "INFO"

    foreach ($app in $appsToRemove) {
        Write-Log -Modulo "RemoverApps" -Acao "Buscando pacote: $app" -Tipo "INFO"
        
        # 1. Remove para os usuários atuais
        $package = Get-AppxPackage -Name "*$app*" -AllUsers 2>$null
        if ($package) {
            try {
                $package | Remove-AppxPackage -AllUsers -ErrorAction Stop
                Write-Log -Modulo "RemoverApps" -Acao "Pacote removido (Appx): $app" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "RemoverApps" -Acao "Falha ao remover Appx: $app" -Erro $_.Exception.Message -Tipo "ERROR"
            }
        }
        else {
            Write-Log -Modulo "RemoverApps" -Acao "Pacote Appx não encontrado (já removido): $app" -Tipo "WARNING"
        }
        
        # 2. Remove do provisionamento do Windows (para que não instale em novos usuários)
        $provisioned = Get-AppxProvisionedPackage -Online 2>$null | Where-Object { $_.DisplayName -match $app }
        if ($provisioned) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction Stop | Out-Null
                Write-Log -Modulo "RemoverApps" -Acao "Pacote provisionado removido do sistema: $app" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "RemoverApps" -Acao "Falha ao remover pacote provisionado: $app" -Erro $_.Exception.Message -Tipo "ERROR"
            }
        }
    }

    # 3. Desativação de Serviços Vinculados (Xbox, Mapas)
    Write-Log -Modulo "RemoverApps" -Acao "Desativando serviços residuais vinculados aos apps apagados..." -Tipo "INFO"
    $appServices = @("XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc", "MapsBroker")
    foreach ($svc in $appServices) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            try {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
                Write-Log -Modulo "RemoverApps" -Acao "Serviço residual desativado: $svc" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "RemoverApps" -Acao "Falha ao desativar serviço: $svc" -Erro $_.Exception.Message -Tipo "WARNING"
            }
        }
    }
    
    Write-Log -Modulo "RemoverApps" -Acao "Módulo de exclusão finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "RemoverApps" -Acao "Falha durante execução do módulo de exclusão." -Erro $_.Exception.Message -Tipo "ERROR"
}
