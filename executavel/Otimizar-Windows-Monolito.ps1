<#
.SYNOPSIS
    Script Monolítico de Otimização e Debloat do Windows.
.DESCRIPTION
    Arquivo autocontido que executa em sequência:
    1. Remoção de Bloatwares e Apps Nativos (Edge/Copilot)
    2. Ajuste de Políticas de Privacidade e Telemetria (GPO/Registro)
    3. Otimização de Serviços, Energia e Ajustes Visuais
    4. Limpeza Profunda de Resíduos e Cache
#>

# 1. Validação de Elevação (Administrador)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este executável/script precisa ser executado como Administrador!"
    Start-Sleep -Seconds 3
    exit
}

# 2. Módulo de Logging Embutido
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
    
    if ($PSScriptRoot) {
        $LogDir = Join-Path $PSScriptRoot "logs\$Modulo\$Ano\$Mes\$Dia"
    } else {
        $LogDir = "C:\Logs_Otimizacao\$Modulo\$Ano\$Mes\$Dia"
    }
    
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    }
    
    $LogFile = Join-Path $LogDir "otimizacao.log"
    
    $LogEntry = "[$Timestamp] [$Tipo] $Acao"
    if ($Erro) {
        $LogEntry += " | DETALHE DO ERRO: $Erro"
    }
    
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
    
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

Write-Log -Modulo "Orquestrador" -Acao "Iniciando Executável Único de Otimização do Windows" -Tipo "INFO"

# ==============================================================================
# MÓDULO 1: REMOÇÃO DE APPS E BLOATWARES
# ==============================================================================
Write-Log -Modulo "RemoverApps" -Acao "Iniciando módulo de exclusão de apps" -Tipo "INFO"

try {
    $appsToRemove = @(
        "Microsoft.MSPaint", "Microsoft.WindowsAlarms", "Microsoft.Getstarted", "Microsoft.GetHelp",
        "Microsoft.MicrosoftOfficeHub", "Microsoft.BingFinance", "Microsoft.BingSports", "Microsoft.BingWeather",
        "Microsoft.BingNews", "Microsoft.ZuneVideo", "Microsoft.Paint3D", "Microsoft.Paint",
        "Microsoft.Microsoft3DViewer", "Microsoft.WindowsSoundRecorder", "Microsoft.XboxApp",
        "Microsoft.XboxGamingOverlay", "Microsoft.XboxGameOverlay", "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay", "Microsoft.Xbox.TCUI", "Microsoft.549981C3F5F10",
        "Microsoft.Copilot", "Microsoft.Windows.Ai.Copilot.Provider", "Microsoft.MicrosoftEdge.Stable",
        "MicrosoftWindows.Client.WebExperience", "Clipchamp.Clipchamp", "Microsoft.PowerAutomateDesktop",
        "Microsoft.Todos", "Microsoft.MicrosoftStickyNotes", "Microsoft.YourPhone", "Microsoft.People",
        "microsoft.windowscommunicationsapps", "Microsoft.OneConnect", "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps", "SpotifyAB.SpotifyMusic", "king.com.CandyCrushSaga",
        "king.com.CandyCrushSodaSaga", "king.com.CandyCrushFriends", "NetflixO.Netflix",
        "ROBLOXCORPORATION.ROBLOX", "Facebook.317180B0BB486", "A278AB0D.DisneyMagicKingdoms",
        "DolbyLaboratories.DolbyAccess", "Amazon.com.Amazon", "TikTok", "TencentVideo"
    )

    Write-Log -Modulo "RemoverApps" -Acao "Iniciando varredura de $($appsToRemove.Count) aplicativos..." -Tipo "INFO"

    foreach ($app in $appsToRemove) {
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
        
        $provisioned = Get-AppxProvisionedPackage -Online 2>$null | Where-Object { $_.DisplayName -match $app }
        if ($provisioned) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction Stop | Out-Null
                Write-Log -Modulo "RemoverApps" -Acao "Pacote provisionado removido: $app" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "RemoverApps" -Acao "Falha ao remover pacote provisionado: $app" -Erro $_.Exception.Message -Tipo "ERROR"
            }
        }
    }

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

    # Remoção Edge & Copilot
    try {
        Stop-Process -Name "msedge", "MicrosoftEdgeUpdate", "msedgewebview2", "identity_helper" -Force -ErrorAction SilentlyContinue
        foreach ($edgeSvc in @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")) {
            if (Get-Service -Name $edgeSvc -ErrorAction SilentlyContinue) {
                Stop-Service -Name $edgeSvc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $edgeSvc -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
        Get-ScheduledTask | Where-Object { $_.TaskName -like "*Edge*" } | ForEach-Object {
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
            Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
        }
        $edgeReg = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
        if (Test-Path $edgeReg) { Remove-ItemProperty -Path $edgeReg -Name "NoRemove" -ErrorAction SilentlyContinue }
        
        $edgePaths = @(
            "$env:ProgramFiles (x86)\Microsoft\Edge\Application\*\Installer\setup.exe",
            "$env:ProgramFiles\Microsoft\Edge\Application\*\Installer\setup.exe"
        )
        foreach ($path in $edgePaths) {
            $setupFiles = Resolve-Path $path -ErrorAction SilentlyContinue
            foreach ($setup in $setupFiles) {
                if (Test-Path $setup.Path) {
                    Start-Process -FilePath $setup.Path -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -NoNewWindow -ErrorAction Stop
                }
            }
        }
        Write-Log -Modulo "RemoverApps" -Acao "Desinstalação do Edge concluída." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "RemoverApps" -Acao "Falha no expurgo do Microsoft Edge." -Erro $_.Exception.Message -Tipo "ERROR"
    }

    # Desativação do Copilot
    try {
        $restartExplorerNeeded = $false
        $copilotKeys = @(
            "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
            "HKCU:\Software\Policies\Microsoft\Windows\Sidebar",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sidebar"
        )
        foreach ($key in $copilotKeys) {
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null; $restartExplorerNeeded = $true }
            $valCopilot = (Get-ItemProperty -Path $key -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue).TurnOffWindowsCopilot
            if ($valCopilot -ne 1) { New-ItemProperty -Path $key -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null; $restartExplorerNeeded = $true }
        }

        $taskbarKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $taskbarKey) {
            $showButton = (Get-ItemProperty -Path $taskbarKey -Name "ShowCopilotButton" -ErrorAction SilentlyContinue).ShowCopilotButton
            if ($showButton -ne 0) { New-ItemProperty -Path $taskbarKey -Name "ShowCopilotButton" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null; $restartExplorerNeeded = $true }
        }

        if ($restartExplorerNeeded) {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }
        Write-Log -Modulo "RemoverApps" -Acao "Desativação e checagem do Copilot concluídas." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "RemoverApps" -Acao "Falha ao desativar o Microsoft Copilot." -Erro $_.Exception.Message -Tipo "ERROR"
    }
}
catch {
    Write-Log -Modulo "RemoverApps" -Acao "Falha durante execução do módulo de exclusão." -Erro $_.Exception.Message -Tipo "ERROR"
}

# ==============================================================================
# MÓDULO 2: CONFIGURAÇÕES DE PRIVACIDADE E POLÍTICAS (GPO / REGISTRO)
# ==============================================================================
Write-Log -Modulo "Privacidade" -Acao "Iniciando módulo de políticas e privacidade" -Tipo "INFO"

try {
    function Set-RegistryKey {
        param([string]$Path, [string]$Name, [int]$Value, [string]$Type = "DWord")
        try {
            if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
            if (Test-Path $Path) {
                $existingVal = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
                if ($null -ne $existingVal -and $existingVal -eq $Value) {
                    Write-Log -Modulo "Privacidade" -Acao "RegKey já configurada: $Path\$Name = $Value" -Tipo "INFO"
                    return
                }
            }
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop | Out-Null
            Write-Log -Modulo "Privacidade" -Acao "RegKey definida: $Path\$Name = $Value" -Tipo "INFO"
        }
        catch {
            Write-Log -Modulo "Privacidade" -Acao "RegKey protegida pelo SO/GPO (ignorada): $Path\$Name" -Erro $_.Exception.Message -Tipo "WARNING"
        }
    }

    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "MaxTelemetryAllowed" -Value 1
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

    $cdmPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $cdmKeys = @(
        "FeatureManagementEnabled", "OemPreInstalledAppsEnabled", "PreInstalledAppsEnabled",
        "SilentInstalledAppsEnabled", "SoftLandingEnabled", "SystemPaneSuggestionsEnabled",
        "SubscribedContent-310093Enabled", "SubscribedContent-338387Enabled", "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled", "SubscribedContent-338393Enabled", "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled", "SubscribedContent-353698Enabled"
    )
    foreach ($key in $cdmKeys) { Set-RegistryKey -Path $cdmPath -Name $key -Value 0 }

    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "CreateDesktopShortcutDefault" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "RemoveDesktopShortcutDefault" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "AllowsInstallation" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "InstallDefault" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotEnabled" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-RegistryKey -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sidebar" -Name "TurnOffSidebar" -Value 1
    Set-RegistryKey -Path "HKCU:\Software\Policies\Microsoft\Windows\Sidebar" -Name "TurnOffSidebar" -Value 1
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "EnableFeeds" -Value 0
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0

    Write-Log -Modulo "Privacidade" -Acao "Módulo de políticas finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "Privacidade" -Acao "Falha durante execução do módulo de políticas." -Erro $_.Exception.Message -Tipo "ERROR"
}

# ==============================================================================
# MÓDULO 3: CONFIGURAÇÕES GERAIS DO WINDOWS
# ==============================================================================
Write-Log -Modulo "ConfigGerais" -Acao "Iniciando módulo de configuração do Windows" -Tipo "INFO"

try {
    try {
        $tempDirs = @("$env:windir\Temp\*", "$env:LOCALAPPDATA\Temp\*")
        foreach ($dir in $tempDirs) { Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log -Modulo "ConfigGerais" -Acao "Limpeza de Temp e Lixeira concluída." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Aviso não crítico durante limpeza." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    try {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Log -Modulo "ConfigGerais" -Acao "Plano de energia alterado com sucesso." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Falha ao alterar plano de energia." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    $servicesToDisable = @("DiagTrack", "dmwappushservice", "Fax")
    foreach ($svc in $servicesToDisable) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            try {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
                Write-Log -Modulo "ConfigGerais" -Acao "Serviço desativado permanentemente: $svc" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "ConfigGerais" -Acao "Não foi possível desativar o serviço: $svc" -Erro $_.Exception.Message -Tipo "WARNING"
            }
        }
    }

    try {
        function Set-RegKeySafe {
            param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
            try {
                if (Test-Path $Path) {
                    $existingVal = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
                    if ($null -ne $existingVal -and $existingVal -eq $Value) { return }
                } else {
                    New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
                }
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log -Modulo "ConfigGerais" -Acao "RegKey protegida/ignorada: $Path\$Name" -Erro $_.Exception.Message -Tipo "WARNING"
            }
        }

        Set-RegKeySafe -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
        Set-RegKeySafe -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
        Set-RegKeySafe -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type "String"
        Set-RegKeySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0

        Write-Log -Modulo "ConfigGerais" -Acao "Ajustes de interface aplicados com sucesso." -Tipo "SUCCESS"
    }
    catch {
        Write-Log -Modulo "ConfigGerais" -Acao "Falha ao aplicar ajustes de interface." -Erro $_.Exception.Message -Tipo "WARNING"
    }

    Write-Log -Modulo "ConfigGerais" -Acao "Módulo de configurações gerais finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "ConfigGerais" -Acao "Falha durante execução do módulo de configurações gerais." -Erro $_.Exception.Message -Tipo "ERROR"
}

# ==============================================================================
# MÓDULO 4: LIMPEZA DE ARQUIVOS RESIDUAIS E CACHE
# ==============================================================================
Write-Log -Modulo "LimparResiduos" -Acao "Iniciando módulo de limpeza de arquivos residuais" -Tipo "INFO"

try {
    $appTargets = @(
        "Microsoft.MSPaint", "Microsoft.WindowsAlarms", "Microsoft.Getstarted", "Microsoft.GetHelp",
        "Microsoft.MicrosoftOfficeHub", "Microsoft.BingFinance", "Microsoft.BingSports", "Microsoft.BingWeather",
        "Microsoft.BingNews", "Microsoft.ZuneVideo", "Microsoft.Paint3D", "Microsoft.Paint",
        "Microsoft.Microsoft3DViewer", "Microsoft.WindowsSoundRecorder", "Microsoft.XboxApp",
        "Microsoft.XboxGamingOverlay", "Microsoft.XboxGameOverlay", "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay", "Microsoft.Xbox.TCUI", "Microsoft.549981C3F5F10",
        "Microsoft.Copilot", "Microsoft.Windows.Ai.Copilot.Provider", "Microsoft.MicrosoftEdge",
        "Microsoft.MicrosoftEdge.Stable", "MicrosoftWindows.Client.WebExperience", "Clipchamp.Clipchamp",
        "Microsoft.PowerAutomateDesktop", "Microsoft.Todos", "Microsoft.MicrosoftStickyNotes",
        "Microsoft.YourPhone", "Microsoft.People", "microsoft.windowscommunicationsapps",
        "Microsoft.OneConnect", "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "SpotifyAB.SpotifyMusic", "king.com.CandyCrushSaga", "king.com.CandyCrushSodaSaga",
        "king.com.CandyCrushFriends", "NetflixO.Netflix", "ROBLOXCORPORATION.ROBLOX",
        "Facebook.317180B0BB486", "A278AB0D.DisneyMagicKingdoms", "DolbyLaboratories.DolbyAccess",
        "Amazon.com.Amazon", "TikTok", "TencentVideo"
    )

    $packagesPath = Join-Path $env:LOCALAPPDATA "Packages"
    if (Test-Path $packagesPath) {
        foreach ($target in $appTargets) {
            $matchingDirs = Get-ChildItem -Path $packagesPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$target*" }
            foreach ($dir in $matchingDirs) {
                try {
                    Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
                    Write-Log -Modulo "LimparResiduos" -Acao "Diretório de AppX excluído: $($dir.Name)" -Tipo "SUCCESS"
                }
                catch {
                    Write-Log -Modulo "LimparResiduos" -Acao "Aviso ao remover pasta AppX: $($dir.Name)" -Erro $_.Exception.Message -Tipo "WARNING"
                }
            }
        }
    }

    $edgeSystemPaths = @(
        "$env:ProgramFiles (x86)\Microsoft\Edge",
        "$env:ProgramFiles\Microsoft\Edge",
        "$env:ProgramData\Microsoft\EdgeUpdate",
        "$env:LOCALAPPDATA\Microsoft\Edge",
        "$env:APPDATA\Microsoft\Edge"
    )
    foreach ($edgeDir in $edgeSystemPaths) {
        if (Test-Path $edgeDir) {
            try {
                Remove-Item -Path $edgeDir -Recurse -Force -ErrorAction Stop
                Write-Log -Modulo "LimparResiduos" -Acao "Diretório residual do Edge excluído: $edgeDir" -Tipo "SUCCESS"
            }
            catch {
                Write-Log -Modulo "LimparResiduos" -Acao "Não foi possível remover totalmente a pasta do Edge: $edgeDir" -Erro $_.Exception.Message -Tipo "WARNING"
            }
        }
    }

    $systemTempDirs = @(
        "$env:windir\SoftwareDistribution\Download\*",
        "$env:windir\Prefetch\*",
        "$env:LOCALAPPDATA\D3DSCache\*",
        "$env:LOCALAPPDATA\CrashDumps\*"
    )
    foreach ($sysTemp in $systemTempDirs) {
        try {
            Remove-Item -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log -Modulo "LimparResiduos" -Acao "Falha ao esvaziar pasta de cache: $sysTemp" -Erro $_.Exception.Message -Tipo "WARNING"
        }
    }

    Write-Log -Modulo "LimparResiduos" -Acao "Módulo de limpeza de resíduos finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "LimparResiduos" -Acao "Falha durante execução do módulo de limpeza de resíduos." -Erro $_.Exception.Message -Tipo "ERROR"
}

Write-Log -Modulo "Orquestrador" -Acao "Otimização completa finalizada com sucesso." -Tipo "SUCCESS"
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host " OTIMIZAÇÃO CONCLUÍDA COM SUCESSO!                     " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Pressione qualquer tecla para fechar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
