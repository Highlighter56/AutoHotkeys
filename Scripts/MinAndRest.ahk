#Requires AutoHotkey v2.0
#SingleInstance Force

global LastMinimizedID := 0
global WasMaximized := false

IsSkippableWindowClass(winClass)
{
    return (winClass = "WorkerW" || winClass = "Progman" || winClass = "Shell_TrayWnd")
}

IsValidWindow(hwnd)
{
    if (!hwnd)
        return false

    return WinExist("ahk_id " hwnd)
}

; --- MINIMIZE SHORTCUT: Ctrl + Alt + M ---
^!m::
{
    global LastMinimizedID, WasMaximized
    ActiveHWND := WinExist("A")

    if (IsValidWindow(ActiveHWND))
    {
        WinClass := WinGetClass("ahk_id " ActiveHWND)
        if (!IsSkippableWindowClass(WinClass))
        {
            LastMinimizedID := ActiveHWND
            WasMaximized := (WinGetMinMax("ahk_id " ActiveHWND) == 1)
            WinMinimize("ahk_id " ActiveHWND)
        }
    }
}

; --- RESTORE SHORTCUT: Ctrl + Alt + R ---
^!r::
{
    global LastMinimizedID, WasMaximized

    if (IsValidWindow(LastMinimizedID))
    {
        MinMaxState := WinGetMinMax("ahk_id " LastMinimizedID)

        if (MinMaxState == -1)
        {
            if (WasMaximized)
                WinMaximize("ahk_id " LastMinimizedID)
            else
                WinRestore("ahk_id " LastMinimizedID)

            WinActivate("ahk_id " LastMinimizedID)
        }
    }
}