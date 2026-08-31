#Requires AutoHotkey v2.0
#SingleInstance Force

global SkylineState := Map(
    "TrackedOrder", [],
    "TrackedWindows", Map(),
    "ListHwnd", 0,
    "ListTitle", "Skyline - Tracked Windows",
    "DataDir", A_ScriptDir . "\Data",
    "RegistryPath", A_ScriptDir . "\Data\SkylineAppRegistry.json",
    "PresetsPath", A_ScriptDir . "\Data\SkylinePresets.json"
)

WriteTextFile(path, text)
{
    file := FileOpen(path, "w")
    if (!file)
        throw Error("Unable to open file for writing: " path)

    file.Write(text)
    file.Close()
}

JoinArrayValues(values, delimiter := "|")
{
    if (!IsObject(values))
        return ""

    result := ""
    for index, value in values
    {
        if (index > 1)
            result .= delimiter
        result .= value
    }

    return result
}

EnsureDataFiles()
{
    global SkylineState

    DirCreate(SkylineState["DataDir"])

    if (!FileExist(SkylineState["RegistryPath"]))
        WriteTextFile(SkylineState["RegistryPath"], '{"Apps":{}}')

    if (!FileExist(SkylineState["PresetsPath"]))
        WriteTextFile(SkylineState["PresetsPath"], '{"Presets":{}}')
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

NormalizePath(path)
{
    if (!path)
        return ""

    path := StrReplace(path, "/", "\")
    return StrLower(Trim(path))
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

    ; Non-GUI list mode intentionally keeps the list as a simple message flow.
    ; The GUI prototype is preserved in Temp/Skyline.GuiPrototype_2026-08-30.ahk.
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

    listText := FormatTrackedSummary()
    ListHwnd := MsgBox(listText, "Skyline - Tracked Windows", "OK")
    SkylineState["ListHwnd"] := ListHwnd
    SkylineState["ListTitle"] := "Skyline - Tracked Windows"
    ShowStatus("Tracked list opened")
}

GetAppRegistry()
{
    global SkylineState

    filePath := SkylineState["RegistryPath"]
    if (!FileExist(filePath))
        EnsureDataFiles()

    if (!FileExist(filePath))
        return Map()

    raw := FileRead(filePath)
    if (Trim(raw) = "")
        return Map()

    registry := Map()
    for line in StrSplit(raw, "`n", "`r")
    {
        line := Trim(line)
        if (line = "")
            continue

        splitIndex := InStr(line, "=")
        if (!splitIndex)
            continue

        appName := Trim(SubStr(line, 1, splitIndex - 1))
        appPath := Trim(SubStr(line, splitIndex + 1))
        if (appName != "" && appPath != "")
            registry[appName] := appPath
    }

    return registry
}

SaveAppRegistry(registry)
{
    global SkylineState

    lines := []
    for appName, appPath in registry
        lines.Push(appName "=" appPath)

    WriteTextFile(SkylineState["RegistryPath"], lines.Length ? JoinArrayValues(lines, "`n") : "")
}

GetPresetData()
{
    global SkylineState

    filePath := SkylineState["PresetsPath"]
    if (!FileExist(filePath))
        EnsureDataFiles()

    if (!FileExist(filePath))
        return Map()

    raw := FileRead(filePath)
    if (Trim(raw) = "")
        return Map()

    presets := Map()
    for line in StrSplit(raw, "`n", "`r")
    {
        line := Trim(line)
        if (line = "")
            continue

        splitIndex := InStr(line, "=")
        if (!splitIndex)
            continue

        slotKey := Trim(SubStr(line, 1, splitIndex - 1))
        serializedValue := Trim(SubStr(line, splitIndex + 1))
        if (slotKey = "")
            continue

        if (serializedValue = "")
            presets[slotKey] := []
        else
            presets[slotKey] := StrSplit(serializedValue, "|")
    }

    return presets
}

SavePresetData(data)
{
    global SkylineState

    lines := []
    for slotKey, value in data
    {
        if (IsObject(value))
            lines.Push(slotKey "=" JoinArrayValues(value, "|"))
        else
            lines.Push(slotKey "=" value)
    }

    WriteTextFile(SkylineState["PresetsPath"], lines.Length ? JoinArrayValues(lines, "`n") : "")
}

GetTrackedAppPaths()
{
    global SkylineState
    paths := []
    seen := Map()

    for _, hwnd in SkylineState["TrackedOrder"]
    {
        if (!IsValidWindow(hwnd) || !SkylineState["TrackedWindows"].Has(hwnd))
            continue

        try
        {
            pid := WinGetPID("ahk_id " hwnd)
            appPath := ProcessGetPath(pid)
        }
        catch
        {
            continue
        }

        normalized := NormalizePath(appPath)
        if (!normalized || seen.Has(normalized))
            continue

        paths.Push(appPath)
        seen[normalized] := true
    }

    return paths
}

RegisterAppPath(appName, executablePath)
{
    if (!appName || !executablePath)
        return

    registry := GetAppRegistry()
    registry[appName] := executablePath
    SaveAppRegistry(registry)
}

FindOpenWindowForPath(executablePath)
{
    targetPath := NormalizePath(executablePath)
    if (!targetPath)
        return 0

    windowList := WinGetList()
    for _, hwnd in windowList
    {
        if (!IsValidWindow(hwnd) || ShouldIgnoreWindowForTracking(hwnd))
            continue

        try
        {
            pid := WinGetPID("ahk_id " hwnd)
            candidatePath := ProcessGetPath(pid)
        }
        catch
        {
            continue
        }

        if (NormalizePath(candidatePath) = targetPath)
            return hwnd
    }

    return 0
}

BrowseForExecutable(prompt)
{
    selected := FileSelect("S", , prompt, "Executables (*.exe)")
    if (!selected)
        return ""

    return selected
}

SavePreset(slot)
{
    global SkylineState

    slotKey := String(slot)
    presetData := GetPresetData()
    presetData[slotKey] := GetTrackedAppPaths()
    SavePresetData(presetData)
    ShowStatus("Saved preset " slot)
}

LoadPreset(slot)
{
    slotKey := String(slot)
    presetData := GetPresetData()

    if (!presetData.Has(slotKey))
    {
        ShowStatus("Preset " slot " empty")
        return
    }

    entries := presetData[slotKey]
    if (!IsObject(entries))
        entries := StrSplit(entries, "|")

    SkylineState["TrackedOrder"] := []
    SkylineState["TrackedWindows"] := Map()

    for _, executablePath in entries
    {
        if (!executablePath)
            continue

        hwnd := FindOpenWindowForPath(executablePath)
        if (hwnd)
        {
            TrackWindow(hwnd)
            continue
        }

        chosenPath := BrowseForExecutable("Locate executable for preset " slot)
        if (!chosenPath)
            continue

        SplitPath(chosenPath, &fileName)
        RegisterAppPath(fileName, chosenPath)
        Run(chosenPath)
        Sleep(250)
        hwnd := FindOpenWindowForPath(chosenPath)
        if (hwnd)
            TrackWindow(hwnd)
    }

    ShowStatus("Activated preset " slot)
}

ClearTrackedWindows(showNotice := true)
{
    global SkylineState
    SkylineState["TrackedOrder"] := []
    SkylineState["TrackedWindows"] := Map()

    if (showNotice)
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

; --- SAVE PRESET SLOT: Ctrl + Alt + 1..9 ---
^!+1::
{
    SavePreset(1)
}
^!+2::
{
    SavePreset(2)
}
^!+3::
{
    SavePreset(3)
}
^!+4::
{
    SavePreset(4)
}
^!+5::
{
    SavePreset(5)
}
^!+6::
{
    SavePreset(6)
}
^!+7::
{
    SavePreset(7)
}
^!+8::
{
    SavePreset(8)
}
^!+9::
{
    SavePreset(9)
}

; --- LOAD PRESET SLOT: 1..9 ---
^!1::
{
    LoadPreset(1)
}
^!2::
{
    LoadPreset(2)
}
^!3::
{
    LoadPreset(3)
}
^!4::
{
    LoadPreset(4)
}
^!5::
{
    LoadPreset(5)
}
^!6::
{
    LoadPreset(6)
}
^!7::
{
    LoadPreset(7)
}
^!8::
{
    LoadPreset(8)
}
^!9::
{
    LoadPreset(9)
}
