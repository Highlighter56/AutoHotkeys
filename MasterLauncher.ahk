#Requires AutoHotkey v2.0

; Get the path of the Scripts directory relative to this launcher
ScriptsFolder := A_ScriptDir . "\Scripts"

; Loop through all .ahk files inside Scripts/ and subfolders
Loop Files, ScriptsFolder . "\*.ahk", "R"
{
    ; Avoid launching Setup or MasterLauncher if accidentally placed inside Scripts
    if (A_LoopFileName != "Setup.bat" && A_LoopFileName != "MasterLauncher.ahk")
    {
        Run(A_LoopFileFullPath)
    }
}