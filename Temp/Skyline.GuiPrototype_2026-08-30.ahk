; TEMP BACKUP ONLY
; This file is intentionally not launched by the startup flow.
; Purpose: preserve the GUI-based prototype from the last pass.
; Known issue: this prototype was introduced before Phase 5 and was rejected for Phase 3.
; The list should remain a simple non-GUI list until the UI work is intentionally scheduled.

#Requires AutoHotkey v2.0
#SingleInstance Force

global SkylineState := Map(
    "TrackedOrder", [],
    "TrackedWindows", Map(),
    "ListHwnd", 0,
    "ListGui", "",
    "ListTextControl", "",
    "ListTitle", "Skyline - Tracked Windows"
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

RemoveTrackedWindowFromOrder(hwnd)
{
    global SkylineState
    TrackedOrder := SkylineState["TrackedOrder"]

    if (!TrackedOrder.Length)
        return

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

ShouldIgnoreWindowForTracking(hwnd)
{
    global SkylineState

    if (!IsValidWindow(hwnd))
        return true

    if (SkylineState["ListHwnd"] && hwnd = SkylineState["ListHwnd"])
        return true

    WinClass := WinGetClass("ahk_id " hwnd)
    if (IsSkippableWindowClass(WinClass))
        return true

    WinTitle := WinGetTitle("ahk_id " hwnd)
    if (WinTitle = SkylineState["ListTitle"])
        return true

    return false
}

TrackWindow(hwnd)
{
    global SkylineState

    if (!IsValidWindow(hwnd))
        return false

    if (ShouldIgnoreWindowForTracking(hwnd))
        return false

    title := WinGetTitle("ahk_id " hwnd)
    if (title = "")
        title := "(untitled)"

    SkylineState["TrackedWindows"][hwnd] := Map(
        "Hwnd", hwnd,
        "Title", title,
        "Class", WinGetClass("ahk_id " hwnd),
        "ProcessName", WinGetProcessName("ahk_id " hwnd),
        "Pid", WinGetPID("ahk_id " hwnd),
        "TrackedAt", A_Now
    )

    MoveTrackedWindowToNewest(hwnd)
    RefreshListWindow(false)
    return true
}

UntrackWindow(hwnd)
{
    global SkylineState
    TrackedWindows := SkylineState["TrackedWindows"]

    if (ShouldIgnoreWindowForTracking(hwnd))
        return

    if (TrackedWindows.Has(hwnd))
        TrackedWindows.Delete(hwnd)

    RemoveTrackedWindowFromOrder(hwnd)
    RefreshListWindow(false)
}

FormatTrackedSummary(maxItems := 10)
{
    global SkylineState
    TrackedOrder := SkylineState["TrackedOrder"]
    TrackedWindows := SkylineState["TrackedWindows"]
    count := TrackedOrder.Length

    if (count = 0)
        return "Tracked windows: 0"

    summary := "Tracked windows: " count "`nNewest first:`n"
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

        summary .= shown ". " title "`n"

        if (shown >= maxItems)
            break
    }

    return summary
}

ShowStatus(message, durationMs := 1200)
{
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
}

RefreshListWindow(forceFocus := false)
{
    global SkylineState

    if (!SkylineState["ListHwnd"] || !IsValidWindow(SkylineState["ListHwnd"]))
        return

    if (SkylineState["ListTextControl"] != "")
        SkylineState["ListTextControl"].Value := FormatTrackedSummary()

    if (forceFocus)
        WinActivate("ahk_id " SkylineState["ListHwnd"])
}

OpenListWindow()
{
    global SkylineState

    if (SkylineState["ListHwnd"] && IsValidWindow(SkylineState["ListHwnd"]))
    {
        RefreshListWindow(true)
        return
    }

    gui := Gui("+AlwaysOnTop +ToolWindow", SkylineState["ListTitle"])
    gui.MarginX := 12
    gui.MarginY := 12
    textControl := gui.Add("Text", "w420 h300 +Wrap", FormatTrackedSummary())
    SkylineState["ListGui"] := gui
    SkylineState["ListTextControl"] := textControl
    SkylineState["ListHwnd"] := gui.Hwnd
    gui.OnEvent("Close", (*) => (
        SkylineState["ListHwnd"] := 0,
        SkylineState["ListGui"] := "",
        SkylineState["ListTextControl"] := ""
    ))
    gui.Show("AutoSize")
    ShowStatus("Tracked list opened")
}

ClearTrackedWindows()
{
    global SkylineState
    SkylineState["TrackedOrder"] := []
    SkylineState["TrackedWindows"] := Map()
    RefreshListWindow(false)
    ShowStatus("Cleared tracked windows")
}

; --- TRACK ACTIVE WINDOW: Ctrl + Alt + T ---
^!t::
{
    ActiveHWND := WinExist("A")

    if (TrackWindow(ActiveHWND))
        ShowStatus("Tracked: " SkylineState["TrackedOrder"].Length)
    else
        ShowStatus("Track skipped")
}

; --- UNTRACK ACTIVE WINDOW: Ctrl + Alt + Shift + T ---
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

; --- LIST TRACKED WINDOWS: Ctrl + Alt + L ---
^!l::
{
    OpenListWindow()
}

; --- CLEAR ALL TRACKED WINDOWS: Ctrl + Alt + X ---
^!x::
{
    ClearTrackedWindows()
}
