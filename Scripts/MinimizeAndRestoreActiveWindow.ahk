#Requires AutoHotkey v2.0
#SingleInstance Force

global SkylineDebug := true
global SkylineDebugLogPath := A_ScriptDir "\\Skyline.debug.log"

global SkylineState := Map(
    "LastMinimizedID", 0,
    "WasMaximized", false,
    "TrackedOrder", [],
    "TrackedWindows", Map()
)

DebugLog(message)
{
    global SkylineDebug, SkylineDebugLogPath

    if (!SkylineDebug)
        return

    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    line := "[" timestamp "] " message "`n"

    OutputDebug(line)
    try FileAppend(line, SkylineDebugLogPath, "UTF-8")
}

ShowStatus(message, durationMs := 1200)
{
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
    DebugLog(message)
}

FormatTrackedSummary(maxItems := 10)
{
    global SkylineState
    TrackedOrder := SkylineState["TrackedOrder"]
    TrackedWindows := SkylineState["TrackedWindows"]
    count := TrackedOrder.Length

    if (count = 0)
        return "Tracked: 0"

    summary := "Tracked: " count "`nNewest first:"
    shown := 0

    Loop count
    {
        reverseIndex := count - A_Index + 1
        hwnd := TrackedOrder[reverseIndex]

        if (!TrackedWindows.Has(hwnd))
            continue

        shown += 1
        info := TrackedWindows[hwnd]
        title := info["Title"]
        if (title = "")
            title := "(untitled)"

        summary .= "`n" shown ". " title

        if (shown >= maxItems)
            break
    }

    return summary
}

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

RemoveTrackedWindowFromOrder(hwnd)
{
    global SkylineState
    TrackedOrder := SkylineState["TrackedOrder"]

    Loop
    {
        FoundIndex := 0

        for Index, TrackedHWND in TrackedOrder
        {
            if (TrackedHWND = hwnd)
            {
                FoundIndex := Index
                break
            }
        }

        if (!FoundIndex)
            break

        TrackedOrder.RemoveAt(FoundIndex)
    }
}

MoveTrackedWindowToNewest(hwnd)
{
    global SkylineState
    TrackedOrder := SkylineState["TrackedOrder"]

    RemoveTrackedWindowFromOrder(hwnd)
    TrackedOrder.Push(hwnd)
}

TrackWindow(hwnd)
{
    global SkylineState

    if (!IsValidWindow(hwnd))
    {
        DebugLog("Track ignored: invalid active window.")
        return false
    }

    WinClass := WinGetClass("ahk_id " hwnd)
    if (IsSkippableWindowClass(WinClass))
    {
        DebugLog("Track ignored: skippable class " WinClass)
        return false
    }

    SkylineState["TrackedWindows"][hwnd] := Map(
        "Hwnd", hwnd,
        "Title", WinGetTitle("ahk_id " hwnd),
        "Class", WinClass,
        "ProcessName", WinGetProcessName("ahk_id " hwnd),
        "Pid", WinGetPID("ahk_id " hwnd),
        "TrackedAt", A_Now
    )

    MoveTrackedWindowToNewest(hwnd)
    DebugLog("Tracked HWND " hwnd " | " SkylineState["TrackedWindows"][hwnd]["Title"])
    return true
}

UntrackWindow(hwnd)
{
    global SkylineState
    TrackedWindows := SkylineState["TrackedWindows"]

    if (TrackedWindows.Has(hwnd))
    {
        TrackedWindows.Delete(hwnd)
        DebugLog("Untracked HWND " hwnd)
    }
    else
    {
        DebugLog("Untrack ignored: HWND not in tracked list.")
    }

    RemoveTrackedWindowFromOrder(hwnd)
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
            ; Keep minimize actions aligned with tracked recency order.
            TrackWindow(ActiveHWND)
            ShowStatus("Minimized and tracked")
            
            WinMinimize("ahk_id " ActiveHWND)
        }
    }
}

; --- TRACK SHORTCUT: Ctrl + Alt + T ---
^!t::
{
    ActiveHWND := WinExist("A")
    if (TrackWindow(ActiveHWND))
        ShowStatus("Tracked: " SkylineState["TrackedOrder"].Length)
    else
        ShowStatus("Track skipped")
}

; --- UNTRACK SHORTCUT: Ctrl + Alt + Shift + T ---
^!+t::
{
    ActiveHWND := WinExist("A")
    beforeCount := SkylineState["TrackedOrder"].Length
    UntrackWindow(ActiveHWND)
    afterCount := SkylineState["TrackedOrder"].Length

    if (afterCount < beforeCount)
        ShowStatus("Untracked: " afterCount)
    else
        ShowStatus("Untrack skipped")
}

; --- LIST TRACKED SHORTCUT: Ctrl + Alt + L ---
^!l::
{
    MsgBox(FormatTrackedSummary(), "Skyline - Tracked Windows")
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
            ShowStatus("Restored last minimized window")
        }
        ; If it's already restored, pressing Ctrl+Alt+R again does nothing at all!
    }
}