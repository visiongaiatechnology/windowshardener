# ---------------------------------------------------------
# APEX GAMING PROTOCOL - DEFENDER (PERFORMANCE & SECURITY)
# Härtet das System, aber lässt Spiele speichern und Mods zu.
# ---------------------------------------------------------

# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
$LogPrefix = "[APEX-GAMING]"

function Write-Log ($Message, $Color="Cyan") {
    Write-Host "$LogPrefix $Message" -ForegroundColor $Color
}

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "FATAL: ADMIN-RECHTE ERFORDERLICH." "Red"; Start-Sleep 3; exit
}

Clear-Host
Write-Log "INITIALISIERE DEFENDER GAMING MODE..." "Magenta"

# ---------------------------------------------------------
# 2. HEURISTIK & CLOUD (BALANCED)
# ---------------------------------------------------------
Write-Log "KONFIGURIERE GAMING-FREUNDLICHE CLOUD..." "Yellow"

# MAPS Advanced für schnelle Prüfung
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendSafeSamples

# Cloud Block Level: 2 (High) statt 6 (Zero Tolerance)
# WICHTIG: Das erlaubt Mods und Trainer, blockt aber bekannte Malware.
Set-MpPreference -CloudBlockLevel 2
Set-MpPreference -CloudExtendedTimeout 50

# PUA Protection (Gegen Werbemüll)
Set-MpPreference -PUAProtection Enabled

# Network Protection
Set-MpPreference -EnableNetworkProtection Enabled

# Scans optimieren (CPU sparen während Gaming)
Set-MpPreference -ScanScheduleDay 0 # Kein automatischer Full-Scan im Hintergrund
Set-MpPreference -DisableRemovableDriveScanning 0

# ---------------------------------------------------------
# 3. ATTACK SURFACE REDUCTION (GAMING SAFE LIST)
# ---------------------------------------------------------
Write-Log "AKTIVIERE ASR-REGELN (EXPLOIT SCHUTZ)..." "Yellow"

# Wir nutzen nur Regeln, die keine Spiele-EXEs blockieren
$ASR_Rules = @{
    "Block abuse of exploited vulnerable signed drivers" = "56a863a9-875e-4185-98a7-b882c64b5ce5";
    "Block credential stealing from lsass.exe" = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2";
    "Block executable content from email client and webmail" = "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550";
    "Block persistence through WMI event subscription" = "e6db77e5-3dde-48c5-9d5b-c63729d70845";
    "Block untrusted and unsigned processes that run from USB" = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4";
    "Use advanced protection against ransomware" = "c1db55ab-c21a-4637-bb3f-a12568109d35"
}

foreach ($RuleName in $ASR_Rules.Keys) {
    $ID = $ASR_Rules[$RuleName]
    try {
        Add-MpPreference -AttackSurfaceReductionRules_Ids $ID -AttackSurfaceReductionRules_Actions Enabled -ErrorAction Stop
    } catch { }
}

# ---------------------------------------------------------
# 4. RANSOMWARE SCHUTZ (DEAKTIVIERT FÜR GAMING)
# ---------------------------------------------------------
Write-Log "DEAKTIVIERE CONTROLLED FOLDER ACCESS..." "Green"
# WICHTIG: Sonst können Spiele nicht speichern!
Set-MpPreference -EnableControlledFolderAccess Disabled

# ---------------------------------------------------------
# 5. FIREWALL HARDENING (BASIC)
# ---------------------------------------------------------
Write-Log "HÄRTE FIREWALL (OHNE LOGGING)..." "Cyan"
$Profiles = @("Domain", "Public", "Private")
foreach ($Profile in $Profiles) {
    # Blockiert eingehende Verbindungen
    Set-NetFirewallProfile -Name $Profile -Enabled True -DefaultInboundAction Block
}

Write-Log "------------------------------------------------" "Cyan"
Write-Log "APEX GAMING: SYSTEM SICHER & SPIELBEREIT." "Green"
Write-Log "Savegames funktionieren. Mods werden nicht sofort gelöscht." "Gray"
Write-Log "------------------------------------------------" "Cyan"
Start-Sleep -Seconds 5