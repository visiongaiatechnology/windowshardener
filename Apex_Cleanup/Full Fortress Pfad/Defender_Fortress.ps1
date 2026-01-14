# ---------------------------------------------------------
# APEX OMEGA PROTOCOL - DEFENDER GOD_MODE (FULL FORTRESS)
# Härtet Microsoft Defender auf das absolute Maximum.
# ---------------------------------------------------------

# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
$LogPrefix = "[OMEGA-FORTRESS]"

function Write-Log ($Message, $Color="Cyan") {
    Write-Host "$LogPrefix $Message" -ForegroundColor $Color
}

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "FATAL: ADMIN-RECHTE ERFORDERLICH." "Red"; Start-Sleep 3; exit
}

Clear-Host
Write-Log "INITIALISIERE DEFENDER GOD_MODE..." "Magenta"

# ---------------------------------------------------------
# 2. HEURISTIK & CLOUD (ZERO TOLERANCE)
# ---------------------------------------------------------
Write-Log "KONFIGURIERE AGGRESSIVE HEURISTIK..." "Red"

Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendSafeSamples
# Level 6: Blockiert ALLES Unbekannte sofort
Set-MpPreference -CloudBlockLevel 6
Set-MpPreference -CloudExtendedTimeout 50
Set-MpPreference -PUAProtection Enabled
Set-MpPreference -EnableNetworkProtection Enabled
Set-MpPreference -DisableRemovableDriveScanning 0
Set-MpPreference -DisableArchiveScanning 0

# ---------------------------------------------------------
# 3. ATTACK SURFACE REDUCTION (THE COMPLETE KILL LIST)
# ---------------------------------------------------------
Write-Log "AKTIVIERE SÄMTLICHE ASR-REGELN (BLOCK MODE)..." "Red"

$ASR_Rules = @{
    "Block abuse of exploited vulnerable signed drivers" = "56a863a9-875e-4185-98a7-b882c64b5ce5";
    "Block Adobe Reader from creating child processes" = "7674ce52-37eb-4751-a02f-8e00ca252d60";
    "Block all Office applications from creating child processes" = "d4f940ab-401b-4efc-aadc-ad5f3c50688a";
    "Block credential stealing from lsass.exe" = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2";
    "Block executable content from email client and webmail" = "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550";
    "Block executable files unless they meet prevalence criteria" = "01443614-9b74-4270-a5db-e0883af26276";
    "Block execution of potentially obfuscated scripts" = "5beb7efe-fd9a-4556-801d-275e5ffc04cc";
    "Block JavaScript or VBScript from launching executables" = "d3e037e1-3eb8-44c8-a917-57927947596d";
    "Block Office applications from creating executable content" = "3b576869-a4ec-4529-8536-b80a7769e899";
    "Block Office applications from injecting code" = "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84";
    "Block Office communication application child processes" = "26190899-1602-49e8-8b27-eb1d0a1ce869";
    "Block persistence through WMI event subscription" = "e6db77e5-3dde-48c5-9d5b-c63729d70845";
    "Block process creations originating from PSExec/WMI" = "d1e49aac-8f56-4280-b9ba-993a6d77406c";
    "Block untrusted and unsigned processes that run from USB" = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4";
    "Block Win32 API calls from Office macros" = "92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b";
    "Use advanced protection against ransomware" = "c1db55ab-c21a-4637-bb3f-a12568109d35"
}

foreach ($RuleName in $ASR_Rules.Keys) {
    $ID = $ASR_Rules[$RuleName]
    try {
        Add-MpPreference -AttackSurfaceReductionRules_Ids $ID -AttackSurfaceReductionRules_Actions Enabled -ErrorAction Stop
        Write-Log " >> ASR ACTIVE: $RuleName" "Green"
    } catch {
        Write-Log " >> ASR ERROR: $RuleName" "DarkGray"
    }
}

# ---------------------------------------------------------
# 4. RANSOMWARE SCHUTZ (CONTROLLED FOLDER ACCESS)
# ---------------------------------------------------------
Write-Log "AKTIVIERE SCHREIB-SPERRE FÜR DOKUMENTE..." "Red"
Set-MpPreference -EnableControlledFolderAccess Enabled

# ---------------------------------------------------------
# 5. FIREWALL HARDENING (MIT LOGGING)
# ---------------------------------------------------------
Write-Log "HÄRTE WINDOWS FIREWALL & LOGGING..." "Cyan"
$Profiles = @("Domain", "Public", "Private")
foreach ($Profile in $Profiles) {
    Set-NetFirewallProfile -Name $Profile -Enabled True -DefaultInboundAction Block
    # Logging ist hier aktiv wie gewünscht
    Set-NetFirewallProfile -Name $Profile -LogFileName "$env:systemroot\system32\LogFiles\Firewall\pfirewall_$Profile.log" -LogMaxSizeKilobytes 4096 -LogBlocked True -LogAllowed False
}

Write-Log "------------------------------------------------" "Cyan"
Write-Log "APEX OMEGA: GOD MODE AKTIV." "Green"
Write-Log "WARNUNG: Unbekannte .exe werden sofort gelöscht." "Yellow"
Write-Log "WARNUNG: Schreibzugriff auf Dokumente gesperrt." "Yellow"
Write-Log "------------------------------------------------" "Cyan"
Start-Sleep -Seconds 5