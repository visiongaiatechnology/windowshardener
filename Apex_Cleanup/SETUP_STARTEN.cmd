@echo off
TITLE APEX OMEGA LAUNCHER (HYBRID V6)
CLS
COLOR 0A

ECHO [SYSTEM CHECK] Suche nach PowerShell Versionen...
ECHO.

SET "PWSH_EXE="

:: 1. Check Standard Pfad
IF EXIST "C:\Program Files\PowerShell\7\pwsh.exe" SET "PWSH_EXE=C:\Program Files\PowerShell\7\pwsh.exe"

:: Falls gefunden, überspringe die globale Suche
IF DEFINED PWSH_EXE GOTO :CHECK_DONE

:: 2. Check Globaler Pfad (nur wenn noch nicht gefunden)
WHERE pwsh >nul 2>nul
IF %ERRORLEVEL% EQU 0 SET "PWSH_EXE=pwsh"

:CHECK_DONE
:: Entscheidung treffen
IF DEFINED PWSH_EXE GOTO :FOUND_V7
GOTO :MISSING_V7

:: ----------------------------------------------------------
:: MODUS A: MODERN (V7 ARCHITECTURE)
:: ----------------------------------------------------------
:FOUND_V7
COLOR 0B
ECHO [ERFOLG] PowerShell 7 gefunden!
ECHO Starte Modern UI (V7 Architecture)...
ECHO.
"%PWSH_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0MENU_V7.ps1"
GOTO :END

:: ----------------------------------------------------------
:: MODUS B: LEGACY (V5 COMPATIBILITY)
:: ----------------------------------------------------------
:MISSING_V7
COLOR 0E
ECHO [INFO] Kein PowerShell 7 gefunden.
ECHO Wechsle in den Kompatibilitaets-Modus (Legacy V5)...
ECHO.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MENU_V5.ps1"
GOTO :END

:END
ECHO.
ECHO [INFO] Launcher beendet.
PAUSE