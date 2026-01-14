# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
Write-Host ">>> STARTE FULL LOCKDOWN (NO COMPROMISE)..." -ForegroundColor Red

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "FATAL: Admin-Rechte fehlen!" -ForegroundColor Red; Start-Sleep 3; exit
}

# Hilfsfunktion
function Add-AppRule ($Name, $Path) {
    if ($Path -and (Test-Path $Path)) {
        New-NetFirewallRule -DisplayName "ALLOW-$Name" -Direction Outbound -Program $Path -Action Allow -ErrorAction SilentlyContinue | Out-Null
        Write-Host " [OK] Whitelist: $Name" -ForegroundColor Green
    } else {
        Write-Host " [SKIP] Nicht gefunden: $Name" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------
# 1. PROTOCOL STERILIZATION (ANTI-SNIFFING)
# ---------------------------------------------------------
Write-Host "[-] Härte LAN-Protokolle..." -ForegroundColor Yellow
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Force
Get-ChildItem "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Force
}

# ---------------------------------------------------------
# 2. GLOBAL LOCKDOWN (DEFAULT DENY)
# ---------------------------------------------------------
# Das ist der harte Schnitt. Ab hier ist alles dicht.
Write-Host "[!!!] AKTIVIERE TOTAL-BLOCKADE..." -ForegroundColor Red
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block

# ---------------------------------------------------------
# 3. SURVIVAL RULES (INFRASTRUKTUR)
# ---------------------------------------------------------
Write-Host "[+] Erlaube Basis-Infrastruktur..." -ForegroundColor Yellow
$Rules = @(
    @{N="APEX-DNS-UDP"; P="UDP"; RP=53},      # Namensauflösung
    @{N="APEX-DNS-TCP"; P="TCP"; RP=53},      # DNS Fallback
    @{N="APEX-DHCP";    P="UDP"; LP=68; RP=67}, # IP-Zuweisung
    @{N="APEX-NTP";     P="UDP"; RP=123},     # Zeit-Synchronisation
    @{N="APEX-WEB-HTTP"; P="TCP"; RP=80},     # Web Basic
    @{N="APEX-WEB-HTTPS"; P="TCP"; RP=443}    # Web Secure
)

foreach ($R in $Rules) {
    $Params = @{DisplayName=$R.N; Direction="Outbound"; Protocol=$R.P; Action="Allow"}
    if ($R.RP) { $Params.Add("RemotePort", $R.RP) }
    if ($R.LP) { $Params.Add("LocalPort", $R.LP) }
    New-NetFirewallRule @Params -ErrorAction SilentlyContinue | Out-Null
}

# ---------------------------------------------------------
# 4. TELEMETRY BINARY BLOCK (LAYER 7 KILL)
# ---------------------------------------------------------
# Doppelte Sicherheit: Namentliche Blockierung
$Binaries = @(
    "$env:windir\System32\CompatTelRunner.exe", 
    "$env:windir\System32\DeviceCensus.exe"
)
foreach ($Bin in $Binaries) {
    New-NetFirewallRule -DisplayName "BLOCK_TELEMETRY" -Direction Outbound -Program $Bin -Action Block -ErrorAction SilentlyContinue | Out-Null
}

# ---------------------------------------------------------
# 5. WHITELIST: GAMING & APPS
# ---------------------------------------------------------
Write-Host "`n--- FREIGABE DER WHITELIST ---" -ForegroundColor Cyan

# Steam, Epic, Battlenet, EA
Add-AppRule "STEAM" "${env:ProgramFiles(x86)}\Steam\steam.exe"
Add-AppRule "STEAM-HELPER" "${env:ProgramFiles(x86)}\Steam\bin\steamwebhelper.exe"
Add-AppRule "STEAM-SERVICE" "${env:ProgramFiles(x86)}\Common Files\Steam\SteamService.exe"
Add-AppRule "EPIC" "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
Add-AppRule "BATTLENET" "${env:ProgramFiles(x86)}\Battle.net\Battle.net.exe"
Add-AppRule "EA-DESKTOP" "${env:ProgramFiles}\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"

# Discord (Findet automatisch die neuste Version)
$DiscordExe = Get-ChildItem "$env:LOCALAPPDATA\Discord\app-*\Discord.exe" | Select-Object -Last 1 -ExpandProperty FullName
Add-AppRule "DISCORD" $DiscordExe

# Browser
Add-AppRule "FIREFOX" "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
Add-AppRule "CHROME" "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
Add-AppRule "EDGE" "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

Write-Host "`n[DONE] SYSTEM VERRIEGELT. NUR WHITELIST IST AKTIV." -ForegroundColor Green
Start-Sleep -Seconds 5