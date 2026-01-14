# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
Write-Host ">>> STARTE SECURITY HARDENING (SYSTEM ABSICHERUNG)..." -ForegroundColor Magenta

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "FATAL: Bitte als Administrator ausführen!" -ForegroundColor Red; Start-Sleep 3; exit
}

# ---------------------------------------------------------
# 1. LATERAL MOVEMENT KILL (STOPPT HACKER IM LAN)
# ---------------------------------------------------------
Write-Host "[-] Deaktiviere Angriffsvektoren im LAN (LLMNR/NetBIOS)..." -ForegroundColor Yellow

# Verhindert "Responder"-Angriffe (Passwort-Klau im Netzwerk)
$RegDNS = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $RegDNS)) { New-Item -Path $RegDNS -Force | Out-Null }
Set-ItemProperty -Path $RegDNS -Name "EnableMulticast" -Value 0 -Force

# Deaktiviert NetBIOS (Veraltetes Protokoll)
Get-ChildItem "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Force
}

# ---------------------------------------------------------
# 2. LEGACY PROTOCOL PURGE (SMBv1 & TUNNELS)
# ---------------------------------------------------------
Write-Host "[-] Deaktiviere veraltete Protokolle (SMBv1 & IPv6 Tunnels)..." -ForegroundColor Yellow

# SMBv1 Kill (Wichtigster Schutz gegen Ransomware wie WannaCry)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -Force
# Deinstalliert das Feature (kann dauern)
Write-Host "    ...Deaktiviere SMBv1 Feature (Bitte warten)..." -ForegroundColor DarkGray
Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null

# Kill IPv6 Tunneling (Schließt Umgehungswege für Firewalls)
netsh interface teredo set state disabled | Out-Null
netsh interface isatap set state disabled | Out-Null
netsh interface 6to4 set state disabled | Out-Null

# ---------------------------------------------------------
# 3. REMOTE ACCESS TERMINATION
# ---------------------------------------------------------
Write-Host "[-] Deaktiviere Fernzugriff (RDP & Remote Assistance)..." -ForegroundColor Yellow

# RDP (Remote Desktop) verbieten
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 -Force

# Remote Assistance (Fernhilfe) verbieten
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0 -Force

Write-Host "`n>>> SICHERHEITSHÄRTUNG ABGESCHLOSSEN." -ForegroundColor Green
Start-Sleep -Seconds 5