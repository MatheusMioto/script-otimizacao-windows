<#
.SYNOPSIS
    Script principal de execução (Orquestrador).
.DESCRIPTION
    Este script orquestra e chama os módulos individuais na ordem correta,
    permitindo criar pontos de restauração e validando permissões de administrador.
#>

# Força execução como Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script precisa ser executado como Administrador!"
    Start-Sleep -Seconds 3
    exit
}

# Importa o módulo de log
. "$PSScriptRoot\scripts\logger.ps1"

Write-Log -Modulo "Orquestrador" -Acao "Iniciando Script Orquestrador de Otimização do Windows" -Tipo "INFO"

try {
    # TODO: (Opcional) Criar ponto de restauração aqui
    Write-Log -Modulo "Orquestrador" -Acao "Verificando módulos a serem executados" -Tipo "INFO"

    # Executando módulos (dot-source para manter o contexto se necessário, ou call direto)
    $scriptPath = $PSScriptRoot

    & "$scriptPath\scripts\01_remover_apps.ps1"
    & "$scriptPath\scripts\02_configurar_privacidade.ps1"
    & "$scriptPath\scripts\03_configurar_windows.ps1"
    & "$scriptPath\scripts\04_limpar_residuos.ps1"
}
catch {
 
    Write-Log -Modulo "Orquestrador" -Acao "Erro fatal na execução do orquestrador" -Erro $_.Exception.Message -Tipo "ERROR"
}
Start-Sleep -Seconds 3
