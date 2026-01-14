<#
.SYNOPSIS
    APEX OMEGA - SYSTEM DIAGNOSTIC TOOL (UNIVERSAL V3.1)
    Kompatibel mit PowerShell 5.1 (Legacy) und PowerShell 7 (Core).
#>

$ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "APEX OMEGA DIAGNOSE"

# 1. INTELLIGENT SELF-ELEVATION (AUTO-ADMIN)
# Funktioniert jetzt für pwsh.exe (V7) UND powershell.exe (V5)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Keine Admin-Rechte erkannt. Starte Diagnose neu..." -ForegroundColor Yellow
    
    # Ermittelt den Pfad zur aktuellen PowerShell-EXE (egal ob v5 oder v7)
    $CurrentExe = (Get-Process -Id $PID).Path
    $ScriptPath = $MyInvocation.MyCommand.Path
    
    # Neustart als Admin
    Start-Process -FilePath $CurrentExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
    exit
}

Clear-Host
# Farben definieren
$C_Head = "Cyan"; $C_Ok = "Green"; $C_Warn = "Yellow"; $C_Err = "Red"; $C_Info = "Gray"

function Print-Line ($Label, $Value, $Status) {
    # 0=OK, 1=WARN, 2=FAIL, 3=SILENT
    $Color = $C_Ok
    if ($Status -eq 1) { $Color = $C_Warn }
    if ($Status -eq 2) { $Color = $C_Err }
    if ($Status -eq 3) { $Color = "Magenta" }
    
    # Formatierung für V5 und V7 kompatibel
    $LabelParsed = "{0,-35}" -f $Label
    Write-Host "$LabelParsed : " -NoNewline -ForegroundColor $C_Info
    Write-Host "$Value" -ForegroundColor $Color
}

Write-Host "==========================================================" -ForegroundColor $C_Head
Write-Host "       APEX OMEGA PROTOCOL - SYSTEM DIAGNOSTICS           " -ForegroundColor $C_Head
Write-Host "==========================================================" -ForegroundColor $C_Head
Write-Host "Zeitstempel: $(Get-Date)" -ForegroundColor $C_Info
Write-Host "Engine     : $($PSVersionTable.PSVersion)" -ForegroundColor $C_Info
Write-Host ""

# ---------------------------------------------------------
# PHASE 1: HYGIENE
# ---------------------------------------------------------
Write-Host ">>> PHASE 1: HYGIENE & DIENSTE" -ForegroundColor $C_Head
$SvcDiag = Get-Service "DiagTrack"
if (!$SvcDiag -or $SvcDiag.Status -eq "Stopped") { Print-Line "Telemetrie Dienst" "GESTOPPT" 0 }
else { Print-Line "Telemetrie Dienst" "LÄUFT (Fail)" 2 }

$Xbox = Get-AppxPackage *XboxApp*
if (!$Xbox) { Print-Line "Bloatware (Xbox)" "SAUBER" 0 }
else { Print-Line "Bloatware (Xbox)" "VORHANDEN" 1 }

# ---------------------------------------------------------
# PHASE 2: NETZWERK
# ---------------------------------------------------------
Write-Host "`n>>> PHASE 2: NETZWERK HARDENING" -ForegroundColor $C_Head
$SMB1 = Get-WindowsOptionalFeature -Online -FeatureName smb1protocol
if ($SMB1.State -ne "Enabled") { Print-Line "SMBv1 (WannaCry)" "DEAKTIVIERT" 0 }
else { Print-Line "SMBv1 (WannaCry)" "AKTIV (Unsicher)" 2 }

$RDP = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
if ($RDP.fDenyTSConnections -eq 1) { Print-Line "Remote Desktop" "GESPERRT" 0 }
else { Print-Line "Remote Desktop" "OFFEN" 1 }

# ---------------------------------------------------------
# PHASE 3: DEFENDER
# ---------------------------------------------------------
Write-Host "`n>>> PHASE 3: DEFENDER KONFIGURATION" -ForegroundColor $C_Head
$Def = Get-MpPreference
$Level = $Def.CloudBlockLevel
if ($Level -eq 2) { Print-Line "Cloud Level" "HIGH (Gaming)" 0 }
elseif ($Level -eq 6) { Print-Line "Cloud Level" "ZERO TOLERANCE (Fortress)" 0 }
else { Print-Line "Cloud Level" "STANDARD ($Level)" 1 }

if ($Def.EnableControlledFolderAccess -eq 1) { Print-Line "Ransomware Schutz" "AKTIV (Block Mode)" 0 }
else { Print-Line "Ransomware Schutz" "AUS (Gaming/Custom)" 1 }

# ---------------------------------------------------------
# PHASE 4: FIREWALL
# ---------------------------------------------------------
Write-Host "`n>>> PHASE 4: FIREWALL STATUS" -ForegroundColor $C_Head
$Profile = Get-NetFirewallProfile -Profile Public
if ($Profile.DefaultOutboundAction -eq "Block") {
    Print-Line "Ausgehender Traffic" "BLOCK ALL (Fortress)" 0
} else {
    Print-Line "Ausgehender Traffic" "ALLOW (Gaming/Custom)" 1
}

$RuleTel = Get-NetFirewallRule -DisplayName "BLOCK_TELEMETRY" -ErrorAction SilentlyContinue
if ($RuleTel) { Print-Line "Telemetrie-Block" "AKTIV" 0 }
else { Print-Line "Telemetrie-Block" "FEHLT" 1 }

# ---------------------------------------------------------
# PHASE 5: UPDATE STATUS
# ---------------------------------------------------------
Write-Host "`n>>> PHASE 5: UPDATE & SILENCE" -ForegroundColor $C_Head
$WU = Get-Service "wuauserv"
if ($WU.StartType -eq "Disabled") { Print-Line "Windows Update" "TOT (Silence Mode)" 3 }
else { Print-Line "Windows Update" "AKTIV" 1 }

# ---------------------------------------------------------
# PHASE 6: DNS CHECK
# ---------------------------------------------------------
Write-Host "`n>>> PHASE 6: DNS PRIVACY" -ForegroundColor $C_Head
# V5-Kompatible Abfrage
$DNS = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null } | Select-Object -ExpandProperty ServerAddresses -First 1

if ($DNS -contains "194.242.2.2") { Print-Line "DNS Provider" "MULLVAD (Verschlüsselt)" 0 }
elseif ($DNS -contains "9.9.9.9") { Print-Line "DNS Provider" "QUAD9 (Gesichert)" 0 }
elseif ($DNS) { Print-Line "DNS Provider" "STANDARD/ISP ($($DNS[0]))" 1 }
else { Print-Line "DNS Provider" "UNBEKANNT" 1 }

Write-Host "`n==========================================================" -ForegroundColor $C_Head
Write-Host "DIAGNOSE ENDE. Drücke Enter."
Read-Host