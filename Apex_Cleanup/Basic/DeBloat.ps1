<#
.SYNOPSIS
    Windows 11 Bloatware & App Exorcism
.DESCRIPTION
    Entfernt vorinstallierte UWP-Apps für den aktuellen Benutzer UND aus dem 
    System-Image (Provisioned Packages), damit sie bei neuen Usern nicht wiederkehren.
#>

# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
$LogPrefix = "[APEX-V5]"

function Write-Log ($Message, $Color="Cyan") {
    Write-Host "$LogPrefix $Message" -ForegroundColor $Color
}

# Admin Check (Zwingend für Provisioned Packages)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "FATAL: DIESES SKRIPT BENÖTIGT ADMIN-RECHTE." "Red"
    Start-Sleep -Seconds 3
    exit
}

Clear-Host
Write-Log "STARTE APP-EXORZISMUS..." "Magenta"

# ---------------------------------------------------------
# DIE LISTE (HIER ANPASSEN, WENN DU ETWAS BEHALTEN WILLST)
# ---------------------------------------------------------
$Bloatware = @(
    "Microsoft.XboxApp", 
    "Microsoft.XboxGamingOverlay", 
    "Microsoft.XboxIdentityProvider", 
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.MicrosoftSolitaireCollection", 
    "Microsoft.ZuneMusic",            # Der moderne Media Player
    "Microsoft.ZuneVideo",            # Filme & TV
    "Microsoft.BingNews", 
    "Microsoft.BingWeather", 
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",           # Erste Schritte
    "Microsoft.Messaging", 
    "Microsoft.Microsoft3DViewer",
    "Microsoft.People", 
    "Microsoft.SkypeApp", 
    "Microsoft.YourPhone",            # Smartphone-Link
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.Windows.Photos",       # ACHTUNG: Die Fotos App
    "Microsoft.WindowsCamera",        # ACHTUNG: Die Kamera App
    "Microsoft.Wallet", 
    "Microsoft.OneConnect",
    "Microsoft.MixedReality.Portal", 
    "Microsoft.549981C3F5F10"         # Cortana
)

# ---------------------------------------------------------
# 1. ENTFERNUNG FÜR DEN AKTUELLEN USER
# ---------------------------------------------------------
Write-Log "PHASE 1: ENTFERNUNG FÜR AKTUELLEN USER (AppxPackage)..." "Yellow"

foreach ($App in $Bloatware) {
    # Prüfen ob vorhanden
    $Package = Get-AppxPackage -Name "*$App*" -ErrorAction SilentlyContinue
    
    if ($Package) {
        Write-Host "  [BUSY] Entferne $($Package.Name)..." -NoNewline
        try {
            $Package | Remove-AppxPackage -ErrorAction Stop
            Write-Host " OK." -ForegroundColor Green
        } catch {
            Write-Host " FEHLER." -ForegroundColor Red
            Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [SKIP] $App nicht gefunden (bereits weg)." -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------
# 2. ENTFERNUNG AUS DEM SYSTEM-IMAGE (PROVISIONED)
# ---------------------------------------------------------
Write-Log "`nPHASE 2: ENTFERNUNG AUS DEM SYSTEM-IMAGE (Provisioned)..." "Yellow"
Write-Log "Lade Paketliste (das kann dauern)..." "Gray"

# Wir holen die Liste nur einmal, das ist viel schneller als in der Schleife
$ProvisionedList = Get-AppxProvisionedPackage -Online

foreach ($App in $Bloatware) {
    # Suche in der geladenen Liste
    $Target = $ProvisionedList | Where-Object { $_.DisplayName -like "*$App*" }
    
    if ($Target) {
        Write-Host "  [KILL] Entferne aus Image: $($Target.DisplayName)..." -NoNewline
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $Target.PackageName -ErrorAction Stop | Out-Null
            Write-Host " TERMINIERT." -ForegroundColor Green
        } catch {
            Write-Host " FEHLER." -ForegroundColor Red
        }
    }
}

Write-Log "`n[+++] EXORCISM COMPLETE." "Green"