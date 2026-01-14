<#
.SYNOPSIS
    Windows 11 Telemetry Lockdown & Hardening Script
.DESCRIPTION
    Dieses Skript deaktiviert diverse Telemetrie-Dienste, geplante Aufgaben,
    setzt Registry-Keys für Datenschutz und blockiert Telemetrie-Binaries in der Firewall.
.NOTES
    Vorsicht: Dies greift tief in das System ein. Einige Windows-Funktionen (z.B. Mail-Sync, Feedback)
    könnten eingeschränkt sein.
#>

# Prüfung auf Administrator-Rechte
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Dieses Skript muss als Administrator ausgeführt werden!"
    Start-Sleep -Seconds 3
    Exit
}

Write-Host ">>> STARTE SYSTEM LOCKDOWN..." -ForegroundColor Cyan

# ---------------------------------------------------------
# 1. SERVICE HARD KILL & LOCKDOWN
# ---------------------------------------------------------
Write-Host "`n[1/4] Stoppe und deaktiviere Dienste..." -ForegroundColor Yellow
$Services = @(
    "DiagTrack",          # Connected User Experiences and Telemetry
    "dmwappushservice",   # WAP Push Message Routing Service (Telemetry)
    "WerSvc",             # Windows Error Reporting
    "OneSyncSvc",         # Sync Host (Hinweis: Kann Mail/Kalender/People Apps beeinträchtigen)
    "wercplsupport",      # Problem Reports and Solutions Control Panel Support
    "PcaSvc"              # Program Compatibility Assistant
)

foreach ($S in $Services) {
    if (Get-Service -Name $S -ErrorAction SilentlyContinue) {
        Write-Host "  -> Verarbeite Dienst: $S" -ForegroundColor Gray
        Stop-Service $S -Force -ErrorAction SilentlyContinue
        Set-Service $S -StartupType Disabled -ErrorAction SilentlyContinue
    } else {
        Write-Host "  -> Dienst nicht gefunden (bereits entfernt?): $S" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------
# 2. SCHEDULED TASK PURGE (IMMUNE SYSTEM KILL)
# ---------------------------------------------------------
Write-Host "`n[2/4] Deaktiviere geplante Telemetrie-Aufgaben..." -ForegroundColor Yellow
$TaskPaths = @(
    "\Microsoft\Windows\Application Experience",
    "\Microsoft\Windows\Customer Experience Improvement Program",
    "\Microsoft\Windows\Feedback",
    "\Microsoft\Windows\Diagnosis"
)

foreach ($Path in $TaskPaths) {
    # Holt alle Tasks im Pfad und deaktiviert sie
    $Tasks = Get-ScheduledTask -TaskPath $Path -ErrorAction SilentlyContinue
    if ($Tasks) {
        Write-Host "  -> Deaktiviere Tasks in: $Path" -ForegroundColor Gray
        $Tasks | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------
# 3. REGISTRY ENFORCEMENT
# ---------------------------------------------------------
Write-Host "`n[3/4] Setze Registry-Richtlinien..." -ForegroundColor Yellow

$RegSettings = @{
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" = @{ "AllowTelemetry" = 0 };
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" = @{ "AllowCortana" = 0; "DisableWebSearch" = 1 }
}

foreach ($Path in $RegSettings.Keys) {
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Host "  -> Pfad erstellt: $Path" -ForegroundColor Gray
    }
    
    foreach ($Name in $RegSettings[$Path].Keys) {
        $Value = $RegSettings[$Path][$Name]
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
        Write-Host "  -> Setze $Name auf $Value" -ForegroundColor Gray
    }
}

# ---------------------------------------------------------
# 4. FIREWALL BINARY BLOCK (REAL KILL)
# ---------------------------------------------------------
Write-Host "`n[4/4] Erstelle Firewall-Blockierregeln..." -ForegroundColor Yellow
$Binaries = @(
    "$env:windir\System32\CompatTelRunner.exe",
    "$env:windir\System32\DeviceCensus.exe"
)

foreach ($Bin in $Binaries) {
    if (Test-Path $Bin) {
        # Entferne alte Regel falls vorhanden, um Duplikate zu vermeiden
        Remove-NetFirewallRule -DisplayName "BLOCK_TELEMETRY_$($Bin | Split-Path -Leaf)" -ErrorAction SilentlyContinue
        
        New-NetFirewallRule -DisplayName "BLOCK_TELEMETRY_$($Bin | Split-Path -Leaf)" `
                            -Direction Outbound `
                            -Program $Bin `
                            -Action Block `
                            -Profile Any `
                            -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  -> Blockiert: $Bin" -ForegroundColor Green
    }
}

Write-Host "`n>>> LOCKDOWN ABGESCHLOSSEN." -ForegroundColor Cyan