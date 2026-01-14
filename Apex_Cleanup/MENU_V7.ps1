<#
.SYNOPSIS
    APEX OMEGA PROTOCOL - HYBRID INTERFACE (GUI & CLI)
#>

$ErrorActionPreference = "Stop"
$CurrentDir = $PSScriptRoot

# 1. AUTO-ADMIN (Self-Elevation)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Exe = (Get-Process -Id $PID).Path
    Start-Process $Exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

# 2. INTERFACE WAHL
Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       APEX OMEGA PROTOCOL - INTERFACE SELECTOR           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " [G] GRAFISCHE OBERFLÄCHE (Fenster mit Klick-Auswahl)" -ForegroundColor Green
Write-Host " [T] TERMINAL (Klassischer Text-Modus)" -ForegroundColor Yellow
Write-Host ""
$GuiChoice = Read-Host " Deine Wahl [G/T] (Enter = Terminal)"

# FUNKTION ZUM AUSFÜHREN DER MODULE (Wird von beiden Modi genutzt)
function Run-Module ($Path, $Name) {
    if (Test-Path $Path) {
        Write-Host " >> [EXEC] $Name..." -ForegroundColor Yellow
        try { & $Path; Write-Host "    [OK]" -ForegroundColor Green } 
        catch { Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red }
    } else { Write-Host "    [MISSING] $Path" -ForegroundColor Red }
}

# ---------------------------------------------------------------------------
# MODUS 1: GRAFISCHE OBERFLÄCHE (GUI)
# ---------------------------------------------------------------------------
if ($GuiChoice -eq "G" -or $GuiChoice -eq "g") {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "APEX OMEGA CONTROL CENTER"
    $Form.Size = New-Object System.Drawing.Size(500,600)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $Form.ForeColor = [System.Drawing.Color]::White

    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = "WÄHLE DEIN SICHERHEITSPROFIL"
    $Label.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $Label.AutoSize = $true
    $Label.Location = New-Object System.Drawing.Point(20,20)
    $Form.Controls.Add($Label)

    # Radio Buttons
    $RadioGaming = New-Object System.Windows.Forms.RadioButton
    $RadioGaming.Text = "GAMING RIG (Performance & Schutz)"
    $RadioGaming.Location = New-Object System.Drawing.Point(30, 70)
    $RadioGaming.Size = New-Object System.Drawing.Size(400, 30)
    $RadioGaming.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $RadioGaming.Checked = $true
    $Form.Controls.Add($RadioGaming)

    $RadioFortress = New-Object System.Windows.Forms.RadioButton
    $RadioFortress.Text = "FORTRESS (Maximaler Lockdown)"
    $RadioFortress.Location = New-Object System.Drawing.Point(30, 110)
    $RadioFortress.Size = New-Object System.Drawing.Size(400, 30)
    $RadioFortress.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $Form.Controls.Add($RadioFortress)

    $RadioCustom = New-Object System.Windows.Forms.RadioButton
    $RadioCustom.Text = "CUSTOM (Benutzerdefiniert)"
    $RadioCustom.Location = New-Object System.Drawing.Point(30, 150)
    $RadioCustom.Size = New-Object System.Drawing.Size(400, 30)
    $RadioCustom.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $Form.Controls.Add($RadioCustom)

    # Custom Options Group
    $GroupCustom = New-Object System.Windows.Forms.GroupBox
    $GroupCustom.Text = "Custom Optionen"
    $GroupCustom.Location = New-Object System.Drawing.Point(30, 200)
    $GroupCustom.Size = New-Object System.Drawing.Size(420, 250)
    $GroupCustom.Visible = $false
    $Form.Controls.Add($GroupCustom)

    $ChkBasic = New-Object System.Windows.Forms.CheckBox; $ChkBasic.Text = "Cleanup (Edge/Bing weg)"; $ChkBasic.Location = New-Object System.Drawing.Point(20,30); $ChkBasic.AutoSize=$true; $ChkBasic.Checked=$true; $GroupCustom.Controls.Add($ChkBasic)
    $ChkDeBloat = New-Object System.Windows.Forms.CheckBox; $ChkDeBloat.Text = "DeBloat (Apps weg)"; $ChkDeBloat.Location = New-Object System.Drawing.Point(20,60); $ChkDeBloat.AutoSize=$true; $ChkDeBloat.Checked=$true; $GroupCustom.Controls.Add($ChkDeBloat)
    $ChkDNS = New-Object System.Windows.Forms.CheckBox; $ChkDNS.Text = "DNS Privacy (Mullvad)"; $ChkDNS.Location = New-Object System.Drawing.Point(20,90); $ChkDNS.AutoSize=$true; $ChkDNS.Checked=$true; $GroupCustom.Controls.Add($ChkDNS)
    $ChkLock = New-Object System.Windows.Forms.CheckBox; $ChkLock.Text = "Lockdown (Telemetrie Kill)"; $ChkLock.Location = New-Object System.Drawing.Point(20,120); $ChkLock.AutoSize=$true; $ChkLock.Checked=$true; $GroupCustom.Controls.Add($ChkLock)
    
    # Toggle Custom Visibility
    $RadioCustom.Add_CheckedChanged({ $GroupCustom.Visible = $RadioCustom.Checked })

    # Start Button
    $BtnStart = New-Object System.Windows.Forms.Button
    $BtnStart.Text = "INSTALLATION STARTEN"
    $BtnStart.Location = New-Object System.Drawing.Point(30, 480)
    $BtnStart.Size = New-Object System.Drawing.Size(420, 50)
    $BtnStart.BackColor = [System.Drawing.Color]::DarkGreen
    $BtnStart.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $BtnStart.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $Form.Controls.Add($BtnStart)

    $Result = $Form.ShowDialog()

    if ($Result -eq "OK") {
        # GUI Logik Auswertung
        $Firewall = "GAMING"; $Defender = "GAMING"
        $Run_Basic=$true; $Run_DeBloat=$true; $Run_DNS=$true; $Run_Lock=$true; $Run_Sec=$true

        if ($RadioFortress.Checked) {
             $Firewall="LOCKDOWN"; $Defender="FORTRESS"
        }
        elseif ($RadioCustom.Checked) {
             $Firewall="GAMING"; $Defender="GAMING" # Standard für Custom
             $Run_Basic=$ChkBasic.Checked; $Run_DeBloat=$ChkDeBloat.Checked; $Run_DNS=$ChkDNS.Checked; $Run_Lock=$ChkLock.Checked
        }
        
        # Ausführen
        $Form.Close()
        Write-Host "GUI START..." -ForegroundColor Cyan
        if ($Run_Lock) { Run-Module "$CurrentDir\Basic\Lockdown.ps1" "Lockdown" }
        if ($Run_Basic) { Run-Module "$CurrentDir\Basic\Cleanup.ps1" "Cleanup" }
        if ($Run_DeBloat) { Run-Module "$CurrentDir\Basic\DeBloat.ps1" "DeBloat" }
        if ($Run_DNS) { Run-Module "$CurrentDir\Basic\DNS_Privacy.ps1" "DNS" }
        if ($Run_Sec) { Run-Module "$CurrentDir\Basic\Security_Hardening_Ghost.ps1" "Hardening" }
        
        if ($Firewall -eq "LOCKDOWN") { Run-Module "$CurrentDir\Full Fortress Pfad\Full_Lockdown.ps1" "Firewall Fortress" }
        else { Run-Module "$CurrentDir\Gaming Pfad\Gaming_Boost.ps1" "Firewall Gaming" }
        
        if ($Defender -eq "FORTRESS") { Run-Module "$CurrentDir\Full Fortress Pfad\Defender_Fortress.ps1" "Defender Fortress" }
        else { Run-Module "$CurrentDir\Gaming Pfad\Defender_Gaming.ps1" "Defender Gaming" }
        
        Write-Host "FERTIG." -ForegroundColor Green
        Read-Host "Enter..."
        exit
    }
    exit
}

# ---------------------------------------------------------------------------
# MODUS 2: TERMINAL (CLI - FALLBACK)
# ---------------------------------------------------------------------------
Write-Host " [1] FORTRESS MODE (Max)" -ForegroundColor Red
Write-Host " [2] GAMING MODE (Empfohlen)" -ForegroundColor Green
Write-Host " [3] CUSTOM MODE" -ForegroundColor Yellow
$Choice = Read-Host " Wahl [1-3]"

$Mod_DNS = $true
Switch ($Choice) {
    "1" { $Firewall="LOCKDOWN"; $Defender="FORTRESS"; $Mod_Basic=$true; $Mod_DeBloat=$true; $Mod_Lockdown=$true; $Mod_SecGhost=$true }
    "2" { $Firewall="GAMING"; $Defender="GAMING"; $Mod_Basic=$true; $Mod_DeBloat=$true; $Mod_Lockdown=$true; $Mod_SecGhost=$true }
    "3" {
        $Mod_Basic    = (Read-Host " [?] Cleanup [J/N]") -match "J|Y"
        $Mod_DeBloat  = (Read-Host " [?] DeBloat [J/N]") -match "J|Y"
        $Mod_DNS      = (Read-Host " [?] DNS Privacy [J/N]") -match "J|Y"
        $Mod_Lockdown = (Read-Host " [?] Lockdown [J/N]") -match "J|Y"
        $Mod_SecGhost = (Read-Host " [?] Hardening [J/N]") -match "J|Y"
        $Firewall     = "GAMING"; $Defender = "GAMING" # Vereinfacht für CLI
    }
}

# Ausführung CLI
if ($Mod_Lockdown) { Run-Module "$CurrentDir\Basic\Lockdown.ps1" "Lockdown" }
if ($Mod_Basic)    { Run-Module "$CurrentDir\Basic\Cleanup.ps1" "Cleanup" }
if ($Mod_DeBloat)  { Run-Module "$CurrentDir\Basic\DeBloat.ps1" "DeBloat" }
if ($Mod_DNS)      { Run-Module "$CurrentDir\Basic\DNS_Privacy.ps1" "DNS" }
if ($Mod_SecGhost) { Run-Module "$CurrentDir\Basic\Security_Hardening_Ghost.ps1" "Hardening" }

if ($Firewall -eq "GAMING")   { Run-Module "$CurrentDir\Gaming Pfad\Gaming_Boost.ps1" "Net Gaming" }
if ($Firewall -eq "LOCKDOWN") { Run-Module "$CurrentDir\Full Fortress Pfad\Full_Lockdown.ps1" "Net Fortress" }

if ($Defender -eq "GAMING")   { Run-Module "$CurrentDir\Gaming Pfad\Defender_Gaming.ps1" "Def Gaming" }
if ($Defender -eq "FORTRESS") { Run-Module "$CurrentDir\Full Fortress Pfad\Defender_Fortress.ps1" "Def Fortress" }

Write-Host "FERTIG." -ForegroundColor Green
Read-Host "Enter..."