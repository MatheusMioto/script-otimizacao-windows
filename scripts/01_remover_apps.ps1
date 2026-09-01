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

# Validação de elevação (Administrador)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log -Modulo "RemoverApps" -Acao "Execução interrompida: Permissão de Administrador necessária." -Tipo "ERROR"
    throw "Execução interrompida: Permissão de Administrador necessária."
}

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
        "Microsoft.Paint",
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
        "Microsoft.Copilot", # Microsoft Copilot App Standalone
        "Microsoft.Windows.Ai.Copilot.Provider", # Copilot Provider (Windows 11)
        "Microsoft.MicrosoftEdge.Stable", # Microsoft Edge Chromium
        "MicrosoftWindows.Client.WebExperience", # Microsoft Copilot e Widgets
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

    # 4. Remoção Forçada (Edge e Copilot)
    Write-Log -Modulo "RemoverApps" -Acao "Executando remoção forçada de componentes bloqueados (Edge e Copilot)..." -Tipo "INFO"
    
    # 4.1 Remoção do Microsoft Edge (Agressiva + Serviços + Tarefas Agendadas)
    try {
        Write-Log -Modulo "RemoverApps" -Acao "Parando serviços, tarefas agendadas e processos do Edge..." -Tipo "INFO"
        Stop-Process -Name "msedge", "MicrosoftEdgeUpdate", "msedgewebview2", "identity_helper" -Force -ErrorAction SilentlyContinue
        
        # Desativa serviços do Edge
        foreach ($edgeSvc in @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")) {
            if (Get-Service -Name $edgeSvc -ErrorAction SilentlyContinue) {
                Stop-Service -Name $edgeSvc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $edgeSvc -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # Desativa e remove tarefas agendadas do Edge
        Get-ScheduledTask | Where-Object { $_.TaskName -like "*Edge*" } | ForEach-Object {
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
            Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
        }

        # Remove chave de proteção do registro (NoRemove)
        $edgeReg = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
        if (Test-Path $edgeReg) {
            Remove-ItemProperty -Path $edgeReg -Name "NoRemove" -ErrorAction SilentlyContinue
        }

        # Remove entradas de inicialização automática no registro
        $runKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        )
        foreach ($rKey in $runKeys) {
            if (Test-Path $rKey) {
                Remove-ItemProperty -Path $rKey -Name "MicrosoftEdgeAutoLaunch" -ErrorAction SilentlyContinue
            }
        }

        $edgePaths = @(
            "$env:ProgramFiles (x86)\Microsoft\Edge\Application\*\Installer\setup.exe",
            "$env:ProgramFiles\Microsoft\Edge\Application\*\Installer\setup.exe"
        )
        
        foreach ($path in $edgePaths) {
            $setupFiles = Resolve-Path $path -ErrorAction SilentlyContinue
            foreach ($setup in $setupFiles) {
                if (Test-Path $setup.Path) {
                    Write-Log -Modulo "RemoverApps" -Acao "Encontrado instalador do Edge: $($setup.Path). Iniciando desinstalação forçada..." -Tipo "INFO"
                    Start-Process -FilePath $setup.Path -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -NoNewWindow -ErrorAction Stop
                }
            }
        }
        Write-Log -Modulo "RemoverApps" -Acao "Desinstalação forçada do Edge concluída." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "RemoverApps" -Acao "Falha na remoção forçada do Microsoft Edge." -Erro $_.Exception.Message -Tipo "ERROR"
    }


    # 4.2 Desativação e Remoção Total do Microsoft Copilot (Com reinício condicional do Explorer)
    try {
        $restartExplorerNeeded = $false
        Write-Log -Modulo "RemoverApps" -Acao "Verificando e desativando Microsoft Copilot no registro..." -Tipo "INFO"
        $copilotKeys = @(
            "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
            "HKCU:\Software\Policies\Microsoft\Windows\Sidebar",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sidebar"
        )
        
        foreach ($key in $copilotKeys) {
            if (-not (Test-Path $key)) {
                New-Item -Path $key -Force | Out-Null
                $restartExplorerNeeded = $true
            }
            $valCopilot = (Get-ItemProperty -Path $key -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue).TurnOffWindowsCopilot
            if ($valCopilot -ne 1) {
                New-ItemProperty -Path $key -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                $restartExplorerNeeded = $true
            }
            $valSidebar = (Get-ItemProperty -Path $key -Name "TurnOffSidebar" -ErrorAction SilentlyContinue).TurnOffSidebar
            if ($valSidebar -ne 1) {
                New-ItemProperty -Path $key -Name "TurnOffSidebar" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                $restartExplorerNeeded = $true
            }
        }
        
        # Oculta o ícone do Copilot da barra de tarefas
        $taskbarKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $taskbarKey) {
            $showButton = (Get-ItemProperty -Path $taskbarKey -Name "ShowCopilotButton" -ErrorAction SilentlyContinue).ShowCopilotButton
            if ($showButton -ne 0) {
                New-ItemProperty -Path $taskbarKey -Name "ShowCopilotButton" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                $restartExplorerNeeded = $true
            }
        }
        
        # Remove pacotes AppX relacionados ao Copilot e WebExperience
        $copilotPackages = Get-AppxPackage -AllUsers "*Copilot*" -ErrorAction SilentlyContinue
        $webExpPackages = Get-AppxPackage -AllUsers "*WebExperience*" -ErrorAction SilentlyContinue
        if ($copilotPackages -or $webExpPackages) {
            Write-Log -Modulo "RemoverApps" -Acao "Removendo pacotes AppX ativos do Copilot..." -Tipo "INFO"
            $copilotPackages | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            $webExpPackages | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            $restartExplorerNeeded = $true
        }
        
        # Remove do provisionamento
        Get-AppxProvisionedPackage -Online 2>$null | Where-Object { $_.DisplayName -match "Copilot" -or $_.DisplayName -match "WebExperience" } | ForEach-Object {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
            $restartExplorerNeeded = $true
        }

        # Reinicia o Explorer APENAS SE NECESSÁRIO
        if ($restartExplorerNeeded) {
            Write-Log -Modulo "RemoverApps" -Acao "Alterações no Copilot detectadas. Reiniciando Windows Explorer..." -Tipo "INFO"
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Log -Modulo "RemoverApps" -Acao "Copilot já estava desativado. Reinício do Explorer omitido." -Tipo "INFO"
        }
        Write-Log -Modulo "RemoverApps" -Acao "Desativação e checagem do Copilot concluídas." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "RemoverApps" -Acao "Falha ao desativar o Microsoft Copilot." -Erro $_.Exception.Message -Tipo "ERROR"
    }

    Write-Log -Modulo "RemoverApps" -Acao "Módulo de exclusão finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "RemoverApps" -Acao "Falha durante execução do módulo de exclusão." -Erro $_.Exception.Message -Tipo "ERROR"
}
