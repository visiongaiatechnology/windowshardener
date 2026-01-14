<#
.SYNOPSIS
    Windows 11 Visual Cleanup & Anti-Bing Script
.DESCRIPTION
    Entfernt Edge Sidebar, Bing-Integration, Widgets, Spotlight-Werbung 
    und erzwingt einen Wallpaper-Refresh.
#>

# 1. INITIALISIERUNG & FUNKTIONEN
$ErrorActionPreference = "Stop"
$LogPrefix = "[APEX-V5]"

function Write-Log ($Message, $Color="Cyan") {
    Write-Host "$LogPrefix $Message" -ForegroundColor $Color
}

function Set-RegistryValue {
    param($Path, $Name, $Value, $Type="DWord")
    try {
        if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
        Write-Log " >> REG SET: $Name = $Value" "Green"
    } catch {
        Write-Log " >> REG ERROR: $($_.Exception.Message)" "Red"
    }
}

# Admin Check (Kritisch für Registry-Zugriffe)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "FATAL: DIESES SKRIPT BENÖTIGT ADMIN-RECHTE." "Red"
    Start-Sleep -Seconds 3
    exit
}

Clear-Host
Write-Log "INITIALISIERE VISUAL CLEANUP (V5)..." "Magenta"

# ---------------------------------------------------------
# 2. EDGE & SEARCH ENGINE KILL (DAS "RECHTE FENSTER")
# ---------------------------------------------------------
Write-Log "DEAKTIVIERE EDGE SIDEBAR & BING INTEGRATION..." "Yellow"

# Edge Policies (Verhindert das Aufpoppen der Sidebar/Suche/Bing-Button)
$RegEdge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Set-RegistryValue -Path $RegEdge -Name "HubsSidebarEnabled" -Value 0
Set-RegistryValue -Path $RegEdge -Name "StandaloneHubsSidebarEnabled" -Value 0
Set-RegistryValue -Path $RegEdge -Name "DefaultSearchProviderContextMenuAccessAllowed" -Value 0

# Windows Search Policies (Verhindert Web-Suche im Startmenü)
$RegSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
Set-RegistryValue -Path $RegSearch -Name "AllowSearchToUseLocation" -Value 0
Set-RegistryValue -Path $RegSearch -Name "DisableWebSearch" -Value 1
Set-RegistryValue -Path $RegSearch -Name "ConnectedSearchUseWeb" -Value 0

# ---------------------------------------------------------
# 3. WIDGETS & EXPERIENCE PACK (DIE ENGINE)
# ---------------------------------------------------------
Write-Log "DEAKTIVIERE WIDGETS ENGINE (WEB EXPERIENCE)..." "Yellow"
# Dies killt das Wetter/News Board unten links
$RegDsh = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
Set-RegistryValue -Path $RegDsh -Name "AllowNewsAndInterests" -Value 0 

# ---------------------------------------------------------
# 4. CLSID AMPUTATION (DAS DESKTOP ICON)
# ---------------------------------------------------------
Write-Log "SUCHE NACH INJIZIERTEN DESKTOP-OBJEKTEN (SPOTLIGHT ICON)..." "Yellow"
# Microsoft injiziert manchmal ein "Erfahren Sie mehr über dieses Bild" Icon
$SpotlightGUID = "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}"
$DesktopNamespacePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$SpotlightGUID"

if (Test-Path $DesktopNamespacePath) {
    try {
        Remove-Item -Path $DesktopNamespacePath -Force -Recurse
        Write-Log " [!!!] CLSID ENTFERNT: Icon physisch gelöscht." "Green"
    } catch {
        Write-Log "FEHLER BEIM ENTFERNEN DER CLSID: $($_.Exception.Message)" "Red"
    }
} else {
    Write-Log " >> Kein Spotlight-Icon gefunden (Sauber)." "Gray"
}

# ---------------------------------------------------------
# 5. REGISTRY KILL SWITCHES (SPOTLIGHT & ADS)
# ---------------------------------------------------------
Write-Log "VERRIEGLE CONTENT DELIVERY MANAGER..." "Yellow"
$RegCDM = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
# Deaktiviert "Vorschläge" im Startmenü und auf dem Sperrbildschirm
Set-RegistryValue -Path $RegCDM -Name "RotatingLockScreenEnabled" -Value 0
Set-RegistryValue -Path $RegCDM -Name "RotatingLockScreenOverlayEnabled" -Value 0
Set-RegistryValue -Path $RegCDM -Name "RotatingDesktopEnabled" -Value 0
Set-RegistryValue -Path $RegCDM -Name "ContentDeliveryAllowed" -Value 0
Set-RegistryValue -Path $RegCDM -Name "SilentInstalledAppsEnabled" -Value 0 # Blockiert Candy Crush & Co.

# Cloud Content Policies
$RegCloud = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
Set-RegistryValue -Path $RegCloud -Name "DisableWindowsSpotlightFeatures" -Value 1
Set-RegistryValue -Path $RegCloud -Name "DisableWindowsConsumerFeatures" -Value 1

# ---------------------------------------------------------
# 6. WALLPAPER HARD RESET (API LEVEL)
# ---------------------------------------------------------
Write-Log "ERZWINGE WALLPAPER-RESET..." "Red"

# Versuche das Standard-Windows-Wallpaper zu finden
$WinWall = "$env:SystemRoot\Web\Wallpaper\Windows\img0.jpg"
if (!(Test-Path $WinWall)) { 
    $WinWall = Get-ChildItem -Path "$env:SystemRoot\Web\Wallpaper" -Recurse -Filter "*.jpg" | Select-Object -First 1 -ExpandProperty FullName
}

if ($WinWall) {
    # C# API Injection für sofortigen Refresh ohne Neustart
    $Code = @'
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@
    
    try {
        # Check ob Typ bereits existiert (wichtig für PS7 Sessions)
        if (-not ([System.Management.Automation.PSTypeName]'Win32Functions.Win32SPI_V5').Type) {
            Add-Type -MemberDefinition $Code -Name "Win32SPI_V5" -Namespace Win32Functions
        }
        
        # Aufruf der API
        [Win32Functions.Win32SPI_V5]::SystemParametersInfo(20, 0, $WinWall, 3) | Out-Null
        Write-Log " >> WALLPAPER ERZWUNGEN: $WinWall" "Green"
    } catch {
        Write-Log " >> API-Fehler, nutze Fallback..." "Red"
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $WinWall -Force
    }
}

# ---------------------------------------------------------
# 7. PROCESS TERMINATION & RESTART
# ---------------------------------------------------------
Write-Log "KILL PROCESSES (EDGE, WIDGETS, SEARCH)..." "Red"

# Beendet Prozesse hart, damit die Registry-Änderungen greifen
Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "Widgets" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue

Write-Log "STARTE EXPLORER NEU..." "Cyan"
Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 2

# Explorer neu starten, falls er nicht von selbst kommt
if (!(Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) { 
    Start-Process "explorer.exe" 
}

Write-Log "SYSTEM BEREINIGT. DIE ENGINE IST DEAKTIVIERT." "Green"