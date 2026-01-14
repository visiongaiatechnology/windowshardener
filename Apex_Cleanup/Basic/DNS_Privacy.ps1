<#
.SYNOPSIS
    Setzt DNS-Server auf Mullvad und Quad9 für alle aktiven Netzwerkadapter.
    Kompatibel mit PowerShell 5.1 und PowerShell 7 (Core).

.DESCRIPTION
    Verwendet das NetTCPIP-Modul (Set-DnsClientServerAddress).
    Primär: 194.242.2.2 (Mullvad)
    Sekundär: 9.9.9.9 (Quad9)
#>

# 1. Administrator-Rechte prüfen
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Dieses Skript muss als Administrator ausgeführt werden!"
    Break
}

# 2. Konfiguration
$DnsServers = @("194.242.2.2", "9.9.9.9")
$InterfaceAlias = "*" # Kann geändert werden, z.B. auf "Ethernet*", um nur LAN zu ändern

try {
    Write-Host "--- Starte DNS-Konfiguration ---" -ForegroundColor Cyan
    
    # Hole alle aktiven Netzwerkadapter (Status 'Up')
    # Wir filtern Loopback aus, da dort DNS-Settings oft nicht greifen oder nötig sind
    $Adapters = Get-NetAdapter -Name $InterfaceAlias | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*Loopback*" }

    if (-not $Adapters) {
        Write-Warning "Keine aktiven Netzwerkadapter gefunden."
        Break
    }

    foreach ($Adapter in $Adapters) {
        Write-Host "Konfiguriere Adapter: $($Adapter.Name) ($($Adapter.InterfaceDescription))..." -NoNewline

        # Setze die DNS-Server
        Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DnsServers -ErrorAction Stop
        
        Write-Host " [OK]" -ForegroundColor Green
    }

    # 3. Validierung
    Write-Host "`n--- Überprüfung der aktuellen Einstellungen ---" -ForegroundColor Cyan
    foreach ($Adapter in $Adapters) {
        $CurrentDNS = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
        Write-Host "$($Adapter.Name): $($CurrentDNS -join ', ')"
    }

}
catch {
    Write-Error "Ein Fehler ist aufgetreten: $($_.Exception.Message)"
}