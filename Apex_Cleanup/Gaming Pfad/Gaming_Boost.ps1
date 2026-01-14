# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
Write-Host ">>> STARTE GAMING PERFORMANCE BOOSTER..." -ForegroundColor Magenta

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "FATAL: Bitte als Administrator ausführen!" -ForegroundColor Red; Start-Sleep 3; exit
}

# ---------------------------------------------------------
# 1. LATENCY & PROTOCOL OPTIMIZATION (PING BOOSTER)
# ---------------------------------------------------------
Write-Host "[-] Deaktiviere LAN-Protokolle (LLMNR/NetBIOS) für besseren Ping..." -ForegroundColor Yellow

# Deaktiviert Multicast Name Resolution (Reduziert Hintergrundrauschen)
$RegDNS = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $RegDNS)) { New-Item -Path $RegDNS -Force | Out-Null }
Set-ItemProperty -Path $RegDNS -Name "EnableMulticast" -Value 0 -Force

# Deaktiviert NetBIOS über TCP/IP
Get-ChildItem "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Force
}

# ---------------------------------------------------------
# 2. SYSTEM RESPONSIVENESS (FPS TWEAKS)
# ---------------------------------------------------------
Write-Host "[+] Optimiere Windows Network Throttling & CPU Priority..." -ForegroundColor Green

$RegSys = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
# NetworkThrottlingIndex: FFFFFFFF = Drosselung komplett aus
Set-ItemProperty -Path $RegSys -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force
# SystemResponsiveness: 0 = Games bekommen 100% CPU Vorrang
Set-ItemProperty -Path $RegSys -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
# Priorität für Spiele erhöhen
Set-ItemProperty -Path "$RegSys\Tasks\Games" -Name "GPU Priority" -Value 8 -Type DWord -Force
Set-ItemProperty -Path "$RegSys\Tasks\Games" -Name "Priority" -Value 6 -Type DWord -Force

# TCP Auto-Tuning sicherstellen (Wichtig für Download-Speed)
netsh int tcp set global autotuninglevel=normal | Out-Null

# ---------------------------------------------------------
# 3. TELEMETRY FIREWALL BLOCK (NUR SPIOSEN)
# ---------------------------------------------------------
Write-Host "[-] Blockiere Telemetrie-Sender in Firewall..." -ForegroundColor Yellow

$Binaries = @(
    "$env:windir\System32\CompatTelRunner.exe", 
    "$env:windir\System32\DeviceCensus.exe",
    "$env:windir\System32\wermgr.exe" 
)

foreach ($Bin in $Binaries) {
    if (Test-Path $Bin) {
        Remove-NetFirewallRule -DisplayName "BLOCK_GAMING_OPT_$($Bin | Split-Path -Leaf)" -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName "BLOCK_GAMING_OPT_$($Bin | Split-Path -Leaf)" `
                            -Direction Outbound -Program $Bin -Action Block `
                            -Profile Any -ErrorAction SilentlyContinue | Out-Null
        Write-Host "    BLOCKED: $Bin" -ForegroundColor Gray
    }
}

Write-Host "`n>>> GAMING OPTIMIERUNG FERTIG. BITTE NEUSTARTEN." -ForegroundColor Cyan
Start-Sleep -Seconds 5