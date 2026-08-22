@echo off
setlocal enabledelayedexpansion

echo =========================================
echo    AutoHotkey v2 Repository Setup
echo =========================================
echo.

:: 1. CHECK & INSTALL AUTOHOTKEY V2
set "AHK_EXE=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
set "AHK_UX=%ProgramFiles%\AutoHotkey\AutoHotkeyUX.exe"
set "AHK_USER_EXE=%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey64.exe"

if exist "%AHK_EXE%" (
    echo [OK] AutoHotkey v2 detected ^(System^).
) else if exist "%AHK_UX%" (
    echo [OK] AutoHotkey UX detected.
) else if exist "%AHK_USER_EXE%" (
    echo [OK] AutoHotkey v2 detected ^(User^).
) else (
    echo [!] AutoHotkey v2 was NOT found. Installing via winget...
    winget install --id AutoHotkey.AutoHotkey -e --source winget
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Installation failed or was canceled. Stopping setup.
        pause
        exit /b 1
    )
    echo [OK] AutoHotkey v2 successfully installed.
)

:: 2. SET DIRECTORY PATHS
set "REPO_DIR=%~dp0"
if "%REPO_DIR:~-1%"=="\" set "REPO_DIR=%REPO_DIR:~0,-1%"
set "SCRIPTS_DIR=%REPO_DIR%\Scripts"
set "LAUNCHER_PATH=%REPO_DIR%\MasterLauncher.ahk"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT_PATH=%STARTUP_FOLDER%\AHK_MasterLauncher.lnk"

if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"

:: 3. VERIFY MASTERLAUNCHER.AHK EXISTS
if not exist "%LAUNCHER_PATH%" (
    echo [ERROR] MasterLauncher.ahk was not found in %REPO_DIR%. Stopping setup.
    pause
    exit /b 1
)

:: 4. CREATE SHORTCUT IN WINDOWS STARTUP (OVERWRITES IF ALREADY EXISTS)
echo [*] Linking MasterLauncher to Windows Startup...
powershell -Command "$wsh = New-Object -ComObject WScript.Shell; $s = $wsh.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%LAUNCHER_PATH%'; $s.WorkingDirectory = '%REPO_DIR%'; $s.Save()" || (
    echo [ERROR] Failed to create Startup shortcut. Stopping setup.
    pause
    exit /b 1
)

:: 5. LAUNCH MASTER LAUNCHER IMMEDIATELY
echo [*] Launching MasterLauncher.ahk...
start "" "%LAUNCHER_PATH%"

echo.
echo =========================================
echo  Setup Complete! Scripts are active.
echo =========================================
pause