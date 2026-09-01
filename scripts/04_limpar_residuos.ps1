<#
.SYNOPSIS
    Script responsável pela limpeza de arquivos residuais, caches e diretórios de apps removidos.
.DESCRIPTION
    Realiza a varredura e expurgo de pastas em AppData, ProgramData e Program Files
    referentes a aplicativos desinstalados (incluindo Edge, Copilot, Spotify e apps UWP).
#>

# Importa o módulo de log
. "$PSScriptRoot\logger.ps1"

Write-Log -Modulo "LimparResiduos" -Acao "Iniciando módulo de limpeza de arquivos residuais" -Tipo "INFO"

try {
    # Lista de padrões de aplicativos para limpeza em AppData\Packages
    $appTargets = @(
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
        "Microsoft.XboxApp",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.Xbox.TCUI",
        "Microsoft.549981C3F5F10",
        "Microsoft.Copilot",
        "Microsoft.Windows.Ai.Copilot.Provider",
        "Microsoft.MicrosoftEdge",
        "Microsoft.MicrosoftEdge.Stable",
        "MicrosoftWindows.Client.WebExperience",
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
        "TencentVideo",
        "Copilot",
        "WebExperience"
    )

    # 1. Limpeza de pastas residuais em AppData\Packages (Apps UWP/Store)
    Write-Log -Modulo "LimparResiduos" -Acao "Varrendo pastas em AppData\Packages..." -Tipo "INFO"
    $appDataLocalPackages = "$env:LOCALAPPDATA\Packages"
    if (Test-Path $appDataLocalPackages) {
        foreach ($app in $appTargets) {
            Get-ChildItem -Path $appDataLocalPackages -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$app*" } | ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                    Write-Log -Modulo "LimparResiduos" -Acao "Pasta residual AppData removida: $($_.Name)" -Tipo "SUCCESS"
                }
                catch {
                    cmd /c rmdir /s /q "$($_.FullName)" 2>$null
                    if (-not (Test-Path $_.FullName)) {
                        Write-Log -Modulo "LimparResiduos" -Acao "Pasta residual AppData limpa via rmdir: $($_.Name)" -Tipo "SUCCESS"
                    }
                    else {
                        Write-Log -Modulo "LimparResiduos" -Acao "Falha ao remover pasta residual AppData: $($_.Name)" -Erro $_.Exception.Message -Tipo "WARNING"
                    }
                }
            }
        }
    }

    # 2. Limpeza de diretórios residuais conhecidos e atalhos do sistema
    Write-Log -Modulo "LimparResiduos" -Acao "Varrendo diretórios conhecidos do Edge, Copilot e apps de terceiros..." -Tipo "INFO"
    $residualPaths = @(
        "$env:LOCALAPPDATA\Spotify",
        "$env:APPDATA\Spotify",
        "${env:ProgramFiles(x86)}\Microsoft\Edge",
        "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate",
        "${env:ProgramFiles(x86)}\Microsoft\EdgeCore",
        "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView",
        "${env:ProgramFiles}\Microsoft\Edge",
        "$env:LOCALAPPDATA\Microsoft\Edge",
        "$env:LOCALAPPDATA\Microsoft\EdgeUpdate",
        "$env:LOCALAPPDATA\Microsoft\EdgeCore",
        "$env:LOCALAPPDATA\Microsoft\EdgeWebView",
        "$env:APPDATA\Microsoft\Edge",
        "$env:PROGRAMDATA\Microsoft\EdgeUpdate",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Copilot.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Copilot.lnk",
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Copilot.lnk",
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Copilot.lnk",
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Copilot.lnk",
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Copilot.lnk"
    )

    # Encerra processos que travam DLLs em memória antes da deleção
    Stop-Process -Name "msedgewebview2", "msedge", "Widgets", "WidgetService", "SearchHost", "PhoneExperienceHost" -Force -ErrorAction SilentlyContinue

    foreach ($path in $residualPaths) {
        if (Test-Path $path) {
            try {
                # Prevenção para pastas do Program Files (TrustedInstaller)
                if ($path -match "Program Files") {
                    cmd /c "echo s | takeown /f ""$path"" /r 2>nul" | Out-Null
                    cmd /c "echo y | takeown /f ""$path"" /r 2>nul" | Out-Null
                    icacls "$path" /grant administrators:F /t /q 2>$null | Out-Null
                }

                # Remove o atributo de 'Somente Leitura'
                if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Attributes = 'Normal' }
                }
                else {
                    (Get-Item $path).Attributes = 'Normal'
                }

                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-Log -Modulo "LimparResiduos" -Acao "Resíduo removido: $path" -Tipo "SUCCESS"
            }
            catch {
                cmd /c "echo s | takeown /f ""$path"" /r 2>nul" | Out-Null
                cmd /c "echo y | takeown /f ""$path"" /r 2>nul" | Out-Null
                icacls "$path" /grant administrators:F /t /q 2>$null | Out-Null
                cmd /c rmdir /s /q "$path" 2>$null
                
                if (Test-Path $path) {
                    try {
                        $tempTrash = "$env:TEMP\trash_debloat_" + [System.IO.Path]::GetRandomFileName()
                        Move-Item -Path $path -Destination $tempTrash -Force -ErrorAction Stop
                        Write-Log -Modulo "LimparResiduos" -Acao "Resíduo bloqueado movido para pasta temporária (%TEMP%): $path" -Tipo "SUCCESS"
                    }
                    catch {
                        Write-Log -Modulo "LimparResiduos" -Acao "Falha ao deletar resíduo (arquivo travado pelo sistema): $path" -Erro $_.Exception.Message -Tipo "WARNING"
                    }
                }
                else {
                    Write-Log -Modulo "LimparResiduos" -Acao "Resíduo removido via takeover/rmdir: $path" -Tipo "SUCCESS"
                }
            }
        }
    }
    
    Write-Log -Modulo "LimparResiduos" -Acao "Módulo de limpeza de resíduos finalizado com sucesso." -Tipo "SUCCESS"
}
catch {
    Write-Log -Modulo "LimparResiduos" -Acao "Falha durante execução do módulo de limpeza de resíduos." -Erro $_.Exception.Message -Tipo "ERROR"
}
