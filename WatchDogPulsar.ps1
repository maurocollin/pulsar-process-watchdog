# ============================================
# WATCHDOG PULSAR - PRODUÇÃO
# ============================================

# =========================
# CONFIGURAÇÃO
# =========================
$apps = @(
    @{ Path = "C:\Pulsar FTP Sulamerica\Ftp_Redispatcher_Sulamerica.exe"; Name = "Ftp_Redispatcher_Sulamerica" },
    @{ Path = "C:\Pulsar FTP Mix\Ftp_Redispatcher_Mix.exe"; Name = "Ftp_Redispatcher_Mix" },
    @{ Path = "C:\Pulsar RDS - PAR\RdsRedispatch_PAR.exe"; Name = "RdsRedispatch_PAR" },
    @{ Path = "C:\Pulsar RDS - MIX\RdsRedispatch_MIX.exe"; Name = "RdsRedispatch_MIX" }
)

$checkInterval = 60
$retryCount = 3
$retryDelay = 5
$maxFailuresBeforeFullRestart = 3

$logFile = "C:\Logs\watchdog_pulsar.log"

# =========================
# GARANTE PASTA DE LOG
# =========================
$logDir = Split-Path $logFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# =========================
# CONTROLE DE INSTÂNCIA ÚNICA
# =========================
$mutex = New-Object System.Threading.Mutex($false, "Global\PulsarWatchdog")

if (-not $mutex.WaitOne(0)) {
    exit
}

# =========================
# FUNÇÃO DE LOG
# =========================
function Write-Log {
    param($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -Append -FilePath $logFile
}

Write-Log "===== INICIANDO WATCHDOG ====="

# =========================
# CONTROLE DE FALHAS
# =========================
$failureCount = @{}

# =========================
# LOOP PRINCIPAL
# =========================
while ($true) {

    $processNames = $apps | ForEach-Object { $_.Name }
    $fullRestartNeeded = $false

    foreach ($app in $apps) {

        if (-not $failureCount.ContainsKey($app.Name)) {
            $failureCount[$app.Name] = 0
        }

        # Verifica se o executável existe
        if (-not (Test-Path $app.Path)) {
            Write-Log "ERRO: Executável não encontrado: $($app.Path)"
            continue
        }

        $proc = Get-Process -Name $app.Name -ErrorAction SilentlyContinue

        # =========================
        # NÃO ESTÁ RODANDO
        # =========================
        if (-not $proc) {
            Write-Log "$($app.Name) não está rodando. Iniciando..."

            try {
                Start-Process -FilePath $app.Path -WindowStyle Minimized
                Start-Sleep -Seconds 5
                $failureCount[$app.Name] = 0
            }
            catch {
                Write-Log "ERRO ao iniciar $($app.Name): $_"
                $failureCount[$app.Name]++
            }

            continue
        }

        # =========================
        # VERIFICA TRAVAMENTO
        # =========================
        $notResponding = $true

        for ($i = 0; $i -lt $retryCount; $i++) {
            if ($proc.Responding) {
                $notResponding = $false
                break
            }
            Start-Sleep -Seconds $retryDelay
            $proc.Refresh()
        }

        if ($notResponding) {
            Write-Log "ALERTA: $($app.Name) travado."

            $failureCount[$app.Name]++

            try {
                Stop-Process -Name $app.Name -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Start-Process -FilePath $app.Path -WindowStyle Minimized
                Write-Log "$($app.Name) reiniciado."
            }
            catch {
                Write-Log "ERRO ao reiniciar $($app.Name): $_"
            }

            if ($failureCount[$app.Name] -ge $maxFailuresBeforeFullRestart) {
                Write-Log "CRÍTICO: $($app.Name) excedeu limite. Reinício geral."
                $fullRestartNeeded = $true
                break
            }
        }
        else {
            $failureCount[$app.Name] = 0
        }
    }

    # =========================
    # RESTART GERAL
    # =========================
    if ($fullRestartNeeded) {

        Write-Log "Reiniciando TODOS os processos..."

        foreach ($app in $apps) {
            Stop-Process -Name $app.Name -Force -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 5

        $allClosed = $false

        while (-not $allClosed) {
            $openRemaining = Get-Process -Name $processNames -ErrorAction SilentlyContinue

            if ($null -eq $openRemaining) {
                $allClosed = $true
            }
            else {
                $openRemaining | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        }

        foreach ($app in $apps) {
            try {
                Start-Process -FilePath $app.Path -WindowStyle Minimized
            }
            catch {
                Write-Log "ERRO ao iniciar $($app.Name): $_"
            }
        }

        $failureCount.Clear()

        Write-Log "Reinício geral concluído."
    }

    Start-Sleep -Seconds $checkInterval
}