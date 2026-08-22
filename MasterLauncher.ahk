#Requires AutoHotkey v2.0
#NoTrayIcon

ScriptsDir := "' . ScriptsFolder . '"

; R flag enables recursive scanning through all subfolders
Loop Files, ScriptsDir . "\*.ahk", "R"
{
    Run(A_LoopFileFullPath)
}