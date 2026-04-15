# --- CONFIGURAÇÃO ---
$apps = @(
    @{ Path = "C:\Pulsar FTP Sulamerica\Ftp_Redispatcher_Sulamerica.exe"; Name = "Ftp_Redispatcher_Sulamerica" },
    @{ Path = "C:\Pulsar FTP Mix\Ftp_Redispatcher_Mix.exe"; Name = "Ftp_Redispatcher_Mix" },
    @{ Path = "C:\Pulsar RDS - PAR\RdsRedispatch_PAR.exe"; Name = "RdsRedispatch_PAR" },
    @{ Path = "C:\Pulsar RDS - MIX\RdsRedispatch_MIX.exe"; Name = "RdsRedispatch_MIX" }
)

$checkInterval = 20 # Intervalo de verificação em segundos

Write-Host "Iniciando Watchdog Pulsar... Mantenha esta janela aberta." -ForegroundColor Cyan

while($true) {
    $currentTime = Get-Date -Format "HH:mm:ss"
    $fullRestartNeeded = $false

    foreach ($app in $apps) {
        $proc = Get-Process -Name $app.Name -ErrorAction SilentlyContinue

        # 1. VERIFICA SE O PROGRAMA ESTÁ ABERTO
        if (-not $proc) {
            Write-Host "[$currentTime] $($app.Name) não encontrado. Iniciando..." -ForegroundColor Yellow
            try {
                Start-Process -FilePath $app.Path -WindowStyle Minimized
                Start-Sleep -Seconds 2 # Aguarda um pouco antes de checar o próximo
            } catch {
                Write-Host "ERRO ao abrir $($app.Name)" -ForegroundColor Red
            }
        } 
        # 2. VERIFICA SE O PROGRAMA TRAVOU (NOT RESPONDING)
        elseif (-not $proc.Responding) {
            Write-Host "[$currentTime] FALHA CRÍTICA: $($app.Name) travou." -ForegroundColor Red
            $fullRestartNeeded = $true
            break # Sai do foreach para reiniciar tudo
        }
    }

    # SE ALGUÉM TRAVOU, FECHA TUDO E REABRE DO ZERO
    if ($fullRestartNeeded) {
        Write-Host "Reiniciando toda a stack para evitar conflitos..." -ForegroundColor Yellow
        
        foreach ($app in $apps) {
            Stop-Process -Name $app.Name -Force -ErrorAction SilentlyContinue
        }

        # Garante que fecharam
        $allClosed = $false
        while (-not $allClosed) {
            $openRemaining = Get-Process -Name ($apps.Name) -ErrorAction SilentlyContinue
            if ($null -eq $openRemaining) { $allClosed = $true } 
            else { 
                $openRemaining | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2 
            }
        }

        # Reabre todos
        foreach ($app in $apps) {
            Start-Process -FilePath $app.Path -WindowStyle Minimized
        }
        Write-Host "Stack reiniciada com sucesso." -ForegroundColor Green
    }

    # Aguarda o próximo ciclo de monitoramento
    Start-Sleep -Seconds $checkInterval
}