<#
.SYNOPSIS
    APEX OMEGA PROTOCOL - WINDOWS SILENCE (TOTAL ISOLATION)
.DESCRIPTION
    Blockiert sämtliche Telemetrie, Datenübertragung und Windows-Updates.
    Schreibt Hosts-Datei um und deaktiviert Update-Dienste hart.
#>

# 1. INITIALISIERUNG
$ErrorActionPreference = "Stop"
$LogPrefix = "[OMEGA-SILENCE]"

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

function Kill-Service {
    param($Name)
    try {
        $Service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($Service) {
            if ($Service.Status -ne "Stopped") {
                Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $Name -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log " >> SERVICE NEUTRALISIERT: $Name" "Green"
        }
    } catch {
        Write-Log " >> SERVICE LOCK DETECTED: $Name (Versuche Registry-Override...)" "Yellow"
    }
    
    # Registry Hard-Kill (Überschreibt auch geschützte Dienste wie Medic)
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (Test-Path $RegPath) {
        Set-RegistryValue -Path $RegPath -Name "Start" -Value 4
    }
}

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "FATAL: ADMIN-RECHTE ERFORDERLICH." "Red"; Start-Sleep 3; exit
}

Clear-Host
Write-Log "INITIALISIERE DIGITALE ISOLATION..." "Magenta"

# ---------------------------------------------------------
# 2. UPDATE ENGINE LOBOTOMY
# ---------------------------------------------------------
Write-Log "DEAKTIVIERE WINDOWS UPDATE INFRASTRUKTUR..." "Red"

Kill-Service "WaaSMedicSvc"   # Windows Update Medic Service
Kill-Service "UsoSvc"         # Update Orchestrator
Kill-Service "wuauserv"       # Windows Update Core
Kill-Service "bits"           # Background Intelligent Transfer
Kill-Service "dosvc"          # Delivery Optimization

# Registry Policies
$RegAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$RegWU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# NoAutoUpdate = 1 (Aus)
Set-RegistryValue -Path $RegAU -Name "NoAutoUpdate" -Value 1
Set-RegistryValue -Path $RegAU -Name "AUOptions" -Value 2
Set-RegistryValue -Path $RegWU -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1
Set-RegistryValue -Path $RegWU -Name "ExcludeWUDriversInQualityUpdate" -Value 1

# ---------------------------------------------------------
# 3. TELEMETRY DECAPITATION
# ---------------------------------------------------------
Write-Log "NEUTRALISIERE TELEMETRIE-SENSOREN..." "Yellow"

Kill-Service "DiagTrack"
Kill-Service "dmwappushservice"
Kill-Service "WerSvc"
Kill-Service "PcaSvc"

$RegData = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-RegistryValue -Path $RegData -Name "AllowTelemetry" -Value 0
Set-RegistryValue -Path $RegData -Name "DoNotShowFeedbackNotifications" -Value 1

$RegAppCompat = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"
Set-RegistryValue -Path $RegAppCompat -Name "AITEnable" -Value 0
Set-RegistryValue -Path $RegAppCompat -Name "DisableInventory" -Value 1

# ---------------------------------------------------------
# 4. SCHEDULER PURGE
# ---------------------------------------------------------
Write-Log "LÖSCHE GEPLANTE TELEMETRIE-TASKS..." "Cyan"

$Tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)

foreach ($TaskPath in $Tasks) {
    # Extraktion von Pfad und Name für PS-Befehl
    $Parts = $TaskPath.Split('\')
    $TaskName = $Parts[-1]
    $TaskFolder = $TaskPath.Substring(0, $TaskPath.Length - $TaskName.Length - 1)
    
    try {
        Disable-ScheduledTask -TaskPath $TaskFolder -TaskName $TaskName -ErrorAction SilentlyContinue | Out-Null
        Write-Log " >> TASK DEAKTIVIERT: $TaskName" "Green"
    } catch {}
}

# ---------------------------------------------------------
# 5. NETWORK NULL-ROUTING (HOSTS)
# ---------------------------------------------------------
Write-Log "SCHREIBE HOSTS-DATEI (DNS SINKHOLE)..." "Magenta"

$HostsPath = "$env:windir\System32\drivers\etc\hosts"
$BlockedDomains = @(
    "v10.events.data.microsoft.com",
    "v20.events.data.microsoft.com",
    "browser.pipe.aria.microsoft.com",
    "settings-win.data.microsoft.com",
    "watson.telemetry.microsoft.com",
    "telemetry.microsoft.com"
)

try {
    if (!(Test-Path "$HostsPath.bak")) { Copy-Item $HostsPath "$HostsPath.bak" }
    
    $Content = Get-Content $HostsPath -Raw
    $NewEntries = ""
    
    foreach ($Domain in $BlockedDomains) {
        if ($Content -notmatch $Domain) {
            $NewEntries += "`n0.0.0.0 $Domain"
            Write-Log " >> ADDED: $Domain" "Green"
        }
    }
    
    if ($NewEntries.Length -gt 0) {
        Add-Content -Path $HostsPath -Value $NewEntries -Force
    }
} catch {
    Write-Log " >> FEHLER BEI HOSTS DATEI: $($_.Exception.Message)" "Red"
}

# ---------------------------------------------------------
# 6. FINAL CLEANUP
# ---------------------------------------------------------
Write-Log "------------------------------------------------" "Cyan"
Write-Log "APEX OMEGA PROTOCOL ABGESCHLOSSEN." "Green"
Write-Log "WARNUNG: KEINE WINDOWS UPDATES MEHR MÖGLICH." "Red"
Write-Log "------------------------------------------------" "Cyan"
Clear-DnsClientCache
Start-Sleep -Seconds 5