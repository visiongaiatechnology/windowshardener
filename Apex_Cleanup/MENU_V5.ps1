# APEX OMEGA - LEGACY MENU (V5)
# Einfache Version für ältere PowerShell
$ErrorActionPreference = "Stop"
$CurrentDir = $PSScriptRoot

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Bitte Rechtsklick -> Als Administrator ausfuehren!"
    Start-Sleep 5
    exit
}

Clear-Host
Write-Host "=== APEX OMEGA PROTOCOL (LEGACY V5 MODE) ===" -ForegroundColor Cyan
Write-Host "WARNUNG: Du nutzt eine alte PowerShell Version." -ForegroundColor Yellow
Write-Host ""
Write-Host "Waehle dein Profil:"
Write-Host "[1] GAMING RIG (Empfohlen)"
Write-Host "[2] FORTRESS (Experten)"
Write-Host ""
$Choice = Read-Host "Auswahl [1/2]"

if ($Choice -eq "1") {
    Write-Host ">>> STARTE GAMING MODE..." -ForegroundColor Green
    & "$CurrentDir\Basic\Lockdown.ps1"
    & "$CurrentDir\Basic\Cleanup.ps1"
    & "$CurrentDir\Basic\DeBloat.ps1"
    & "$CurrentDir\Basic\DNS_Privacy.ps1"
    & "$CurrentDir\Basic\Security_Hardening_Ghost.ps1"
    & "$CurrentDir\Gaming Pfad\Gaming_Boost.ps1"
    & "$CurrentDir\Gaming Pfad\Defender_Gaming.ps1"
}
elseif ($Choice -eq "2") {
    Write-Host ">>> STARTE FORTRESS MODE..." -ForegroundColor Red
    & "$CurrentDir\Basic\Lockdown.ps1"
    & "$CurrentDir\Basic\Cleanup.ps1"
    & "$CurrentDir\Basic\DeBloat.ps1"
    & "$CurrentDir\Basic\DNS_Privacy.ps1"
    & "$CurrentDir\Basic\Security_Hardening_Ghost.ps1"
    & "$CurrentDir\Full Fortress Pfad\Full_Lockdown.ps1"
    & "$CurrentDir\Full Fortress Pfad\Defender_Fortress.ps1"
}

Write-Host ""
Write-Host "FERTIG. Bitte PC neustarten."
Read-Host "Enter..."