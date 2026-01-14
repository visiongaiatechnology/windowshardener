<#
.SYNOPSIS
    APEX GATEKEEPER - FORTRESS EDITION
    Öffnet Schilde temporär und stellt danach den PARANOID-MODE wieder her.
#>

$ErrorActionPreference = "Stop"
$ColorGreen = "Green"; $ColorRed = "Red"; $ColorYellow = "Yellow"; $ColorCyan = "Cyan"

function Print-Banner {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor $ColorCyan
    Write-Host "      GATEKEEPER: FORTRESS EDITION            " -ForegroundColor $ColorCyan
    Write-Host "==============================================" -ForegroundColor $ColorCyan
    Write-Host ""
}

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "FATAL: KEINE ADMIN-RECHTE." -ForegroundColor $ColorRed; Start-Sleep 3; exit
}

Print-Banner

# --- PHASE 1: SCHILDE RUNTER ---
Write-Host "[STATUS] SYSTEM WIRD ENTRIEGELT..." -ForegroundColor $ColorYellow
try {
    Set-MpPreference -CloudBlockLevel 0
    Write-Host " >> CLOUD:              MINIMAL (Level 0)" -ForegroundColor $ColorYellow
    Set-MpPreference -EnableControlledFolderAccess Disabled
    Write-Host " >> ORDNER-SCHUTZ:      DEAKTIVIERT" -ForegroundColor $ColorYellow
    Set-MpPreference -EnableNetworkProtection AuditMode
} catch {
    Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor $ColorRed; Read-Host; exit
}

# --- PHASE 2: WARTEZEIT ---
Write-Host "`n==============================================" -ForegroundColor $ColorRed
Write-Host "   WARNUNG: SCHILDE SIND UNTEN (DEFCON 5)     " -ForegroundColor $ColorRed
Write-Host "==============================================" -ForegroundColor $ColorRed
Write-Host "Führe deine Wartung durch und drücke danach ENTER." -ForegroundColor $ColorGreen
Write-Host ""
$null = Read-Host "Drücke [ENTER] für TOTAL LOCKDOWN"

# --- PHASE 3: FORTRESS MODUS WIEDERHERSTELLEN ---
Print-Banner
Write-Host "[STATUS] RE-INITIALISIERUNG (ZERO TOLERANCE)..." -ForegroundColor $ColorRed

try {
    # Level 6 (Zero Tolerance)
    Set-MpPreference -CloudBlockLevel 6
    Write-Host " >> CLOUD:              ZERO TOLERANCE (Level 6)" -ForegroundColor $ColorGreen

    # Ordner Schutz AN (Blockiert Savegames)
    Set-MpPreference -EnableControlledFolderAccess Enabled
    Write-Host " >> ORDNER-SCHUTZ:      AKTIV (BLOCK MODE)" -ForegroundColor $ColorGreen

    Set-MpPreference -EnableNetworkProtection Enabled
    Write-Host " >> NETZWERK-GUARD:     AKTIV" -ForegroundColor $ColorGreen
    Set-MpPreference -PUAProtection Enabled

} catch {
    Write-Host "FEHLER BEIM LOCKDOWN: $($_.Exception.Message)" -ForegroundColor $ColorRed; Read-Host; exit
}

Write-Host "`n[DONE] SYSTEM IST WIEDER EINE FESTUNG." -ForegroundColor $ColorGreen
Start-Sleep -Seconds 3