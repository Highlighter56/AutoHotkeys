#Requires AutoHotkey v2.0

RepoDir := A_ScriptDir
ScriptsFolder := RepoDir . "\Scripts"
StartupFolder := A_Startup
LauncherPath := RepoDir . "\MasterLauncher.ahk"
ShortcutPath := StartupFolder . "\AHK_MasterLauncher.lnk"

; --- 1. Verify AHK v2 Installation ---
AHKKey := "HKLM\SOFTWARE\AutoHotkey"
try {
    InstallVer := RegRead("HKLM\SOFTWARE\AutoHotkey", "Version")
} catch {
    InstallVer := ""
}

if (!InstallVer || SubStr(InstallVer, 1, 1) != "2")
{
    Result := MsgBox("AutoHotkey v2 was not detected on this system.`n`nWould you like to open the official download page now?", "AHK v2 Required", 4 + 48)
    if (Result == "Yes")
        Run("https://www.autohotkey.com/v2/")
    ExitApp()
}

; --- 2. Generate MasterLauncher.ahk ---
LauncherCode := '
(
#Requires AutoHotkey v2.0
#NoTrayIcon

ScriptsDir := "' . ScriptsFolder . '"

; R flag enables recursive scanning through all subfolders
Loop Files, ScriptsDir . "\*.ahk", "R"
{
    Run(A_LoopFileFullPath)
}
)'

FileObj := FileOpen(LauncherPath, "w", "UTF-8")
FileObj.Write(LauncherCode)
FileObj.Close()

; --- 3. Create Startup Shortcut ---
FileCreateShortcut(LauncherPath, ShortcutPath, RepoDir)

; --- 4. Run MasterLauncher ---
Run(LauncherPath)

MsgBox("Setup complete! Your script library is active and configured for system startup.", "Success", 64)