#Requires AutoHotkey v2.0

global SkylineState := Map(
    "LastMinimizedID", 0,
    "WasMaximized", false
)

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
    global SkylineState
    ActiveHWND := WinExist("A")
    
    if (IsValidWindow(ActiveHWND))
    {
        WinClass := WinGetClass("ahk_id " ActiveHWND)
        if (!IsSkippableWindowClass(WinClass))
        {
            SkylineState["LastMinimizedID"] := ActiveHWND
            ; Store 1 if maximized, 0 if normal
            SkylineState["WasMaximized"] := (WinGetMinMax("ahk_id " ActiveHWND) == 1)
            
            WinMinimize("ahk_id " ActiveHWND)
        }
    }
}

; --- RESTORE SHORTCUT: Ctrl + Alt + R ---
^!r::
{
    global SkylineState
    LastMinimizedID := SkylineState["LastMinimizedID"]

    if (IsValidWindow(LastMinimizedID))
    {
        MinMaxState := WinGetMinMax("ahk_id " LastMinimizedID)
        
        ; Only do something if the window is currently minimized (-1)
        if (MinMaxState == -1)
        {
            if (SkylineState["WasMaximized"])
                WinMaximize("ahk_id " LastMinimizedID)
            else
                WinRestore("ahk_id " LastMinimizedID)
                
            WinActivate("ahk_id " LastMinimizedID)
        }
        ; If it's already restored, pressing Ctrl+Alt+R again does nothing at all!
    }
}