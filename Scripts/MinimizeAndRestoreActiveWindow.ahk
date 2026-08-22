#Requires AutoHotkey v2.0

global LastMinimizedID := 0
global WasMaximized := false

; --- MINIMIZE SHORTCUT: Ctrl + Alt + M ---
^!m::
{
    global LastMinimizedID, WasMaximized
    ActiveHWND := WinExist("A")
    
    if (ActiveHWND)
    {
        WinClass := WinGetClass("ahk_id " ActiveHWND)
        if (WinClass != "WorkerW" && WinClass != "Progman" && WinClass != "Shell_TrayWnd")
        {
            LastMinimizedID := ActiveHWND
            ; Store 1 if maximized, 0 if normal
            WasMaximized := (WinGetMinMax("ahk_id " ActiveHWND) == 1)
            
            WinMinimize("ahk_id " ActiveHWND)
        }
    }
}

; --- RESTORE SHORTCUT: Ctrl + Alt + R ---
^!r::
{
    global LastMinimizedID, WasMaximized
    
    if (LastMinimizedID && WinExist("ahk_id " LastMinimizedID))
    {
        MinMaxState := WinGetMinMax("ahk_id " LastMinimizedID)
        
        ; Only do something if the window is currently minimized (-1)
        if (MinMaxState == -1)
        {
            if (WasMaximized)
                WinMaximize("ahk_id " LastMinimizedID)
            else
                WinRestore("ahk_id " LastMinimizedID)
                
            WinActivate("ahk_id " LastMinimizedID)
        }
        ; If it's already restored, pressing Ctrl+Alt+R again does nothing at all!
    }
}