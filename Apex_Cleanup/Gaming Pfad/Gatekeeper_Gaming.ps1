<#
.SYNOPSIS
    APEX GATEKEEPER - GAMING EDITION
    Öffnet Schilde temporär und stellt danach den GAMING-SAFE-MODE wieder her.
#>

$ErrorActionPreference = "Stop"
$ColorGreen = "Green"; $ColorRed = "Red"; $ColorYellow = "Yellow"; $ColorCyan = "Cyan"

function Print-Banner {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor $ColorCyan
    Write-Host "      GATEKEEPER: GAMING EDITION              " -ForegroundColor $ColorCyan
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
    Write-Host " >> CLOUD:              MINIMAL (Installationen erlaubt)" -ForegroundColor $ColorYellow
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
Write-Host "1. Installiere dein Spiel / Update jetzt." -ForegroundColor $ColorGreen
Write-Host "2. Komm hierher zurück, wenn du fertig bist." -ForegroundColor $ColorGreen
Write-Host ""
$null = Read-Host "Drücke [ENTER] um den GAMING-MODUS wiederherzustellen"

# --- PHASE 3: GAMING MODUS WIEDERHERSTELLEN ---
Print-Banner
Write-Host "[STATUS] RE-INITIALISIERUNG (GAMING PROFIL)..." -ForegroundColor $ColorCyan

try {
    # HIER IST DER UNTERSCHIED: Level 2 statt 6
    Set-MpPreference -CloudBlockLevel 2
    Write-Host " >> CLOUD:              HIGH (Level 2 - Mods erlaubt)" -ForegroundColor $ColorGreen

    # HIER IST DER UNTERSCHIED: Disabled lassen für Savegames
    Set-MpPreference -EnableControlledFolderAccess Disabled
    Write-Host " >> ORDNER-SCHUTZ:      DEAKTIVIERT (Savegames OK)" -ForegroundColor $ColorGreen

    Set-MpPreference -EnableNetworkProtection Enabled
    Write-Host " >> NETZWERK-GUARD:     AKTIV" -ForegroundColor $ColorGreen
    Set-MpPreference -PUAProtection Enabled
    Write-Host " >> PUA-ERKENNUNG:      AKTIV" -ForegroundColor $ColorGreen

} catch {
    Write-Host "FEHLER BEIM LOCKDOWN: $($_.Exception.Message)" -ForegroundColor $ColorRed; Read-Host; exit
}

Write-Host "`n[DONE] SYSTEM IST WIEDER IM GAMING-SICHERHEITS-MODUS." -ForegroundColor $ColorGreen
Start-Sleep -Seconds 3