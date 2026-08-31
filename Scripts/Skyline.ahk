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

    createdAny := false

    if (!FileExist(SkylineState["RegistryPath"]))
    {
        WriteTextFile(SkylineState["RegistryPath"], '{"Apps":{}}')
        createdAny := true
    }

    if (!FileExist(SkylineState["PresetsPath"]))
    {
        WriteTextFile(SkylineState["PresetsPath"], '{"Presets":{}}')
        createdAny := true
    }

    ; Phase 4A validation: keep this visible until we confirm the storage files are landing in the expected Data folder.
    if (createdAny)
        ShowStatus("Skyline data ready")
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

ExtractAppInfoFromTrackedWindow(hwnd)
{
    if (!IsValidWindow(hwnd) || !SkylineState["TrackedWindows"].Has(hwnd))
        return Map()

    info := SkylineState["TrackedWindows"][hwnd]
    processName := info["ProcessName"]

    try
    {
        pid := WinGetPID("ahk_id " hwnd)
        appPath := ProcessGetPath(pid)
    }
    catch
    {
        return Map()
    }

    if (!processName || !appPath)
        return Map()

    return Map(
        "AppName", processName,
        "ExecutablePath", appPath
    )
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

    ; Simple JSON parser for {"Apps": {"name": "path", ...}}
    ; Extract the Apps object content
    appsStart := InStr(raw, "{")
    appsEnd := InStr(raw, "}", , -1)

    if (!appsStart || !appsEnd || appsStart >= appsEnd)
        return registry

    content := SubStr(raw, appsStart + 1, appsEnd - appsStart - 1)
    ; Look for "Apps": {..}
    appsKey := InStr(content, "`"Apps`"")
    if (!appsKey)
        return registry

    bracketStart := InStr(content, "{", , appsKey)
    bracketEnd := InStr(content, "}", , bracketStart)
    if (!bracketStart || !bracketEnd)
        return registry

    appsContent := SubStr(content, bracketStart + 1, bracketEnd - bracketStart - 1)

    ; Parse each "name": "path" entry
    for entry in StrSplit(appsContent, ",")
    {
        entry := Trim(entry)
        if (entry = "")
            continue

        ; Remove leading quote from name
        colonPos := InStr(entry, ":")
        if (!colonPos)
            continue

        nameQuoted := SubStr(entry, 1, colonPos - 1)
        pathQuoted := SubStr(entry, colonPos + 1)

        ; Strip quotes and whitespace
        appName := Trim(StrReplace(StrReplace(nameQuoted, "`"", ""), " ", ""))
        appPath := Trim(StrReplace(pathQuoted, "`"", ""))
        appPath := Trim(appPath)
        
        ; Unescape backslashes from JSON format
        appPath := StrReplace(appPath, "\\", "\")

        if (appName != "" && appPath != "")
            registry[appName] := appPath
    }

    return registry
}

SaveAppRegistry(registry)
{
    global SkylineState

    ; Build JSON: {"Apps": {"name": "path", ...}}
    appEntries := []
    for appName, appPath in registry
    {
        ; Escape backslashes in paths for JSON
        escapedPath := StrReplace(appPath, "\", "\\")
        appEntries.Push('"' appName '": "' escapedPath '"')
    }

    appsContent := JoinArrayValues(appEntries, ", ")
    jsonStr := '{"Apps": {' appsContent '}}'
    WriteTextFile(SkylineState["RegistryPath"], jsonStr)
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

    ; Simple approach: find all "N": [...] patterns where N is the slot key
    ; Look for pattern like "1": [{...}], "2": [{...}]
    
    currentPos := 1
    Loop
    {
        ; Find the next slot key (number in quotes)
        quotePos := InStr(raw, '"', , currentPos)
        if (!quotePos)
            break

        nextQuote := InStr(raw, '"', , quotePos + 1)
        if (!nextQuote)
            break

        slotKey := SubStr(raw, quotePos + 1, nextQuote - quotePos - 1)
        
        ; Check if next char after closing quote is a colon (indicating this is a key)
        colonCheck := InStr(raw, ':', , nextQuote)
        if (!colonCheck || colonCheck > nextQuote + 2)
        {
            currentPos := nextQuote + 1
            continue
        }

        ; Found a slot. Now find its array value [...]
        bracketStart := InStr(raw, '[', , colonCheck)
        if (!bracketStart)
        {
            currentPos := nextQuote + 1
            continue
        }

        bracketEnd := InStr(raw, ']', , bracketStart)
        if (!bracketEnd)
        {
            currentPos := nextQuote + 1
            continue
        }

        arrayContent := SubStr(raw, bracketStart + 1, bracketEnd - bracketStart - 1)
        appRecords := []

        ; Parse each {"AppName": "...", "ExecutablePath": "..."} in the array
        objPos := 1
        Loop
        {
            objStart := InStr(arrayContent, '{', , objPos)
            if (!objStart)
                break

            objEnd := InStr(arrayContent, '}', , objStart)
            if (!objEnd)
                break

            objStr := SubStr(arrayContent, objStart + 1, objEnd - objStart - 1)

            ; Extract "AppName": "value"
            appName := ""
            appNamePos := InStr(objStr, '"AppName"')
            if (appNamePos)
            {
                colonPos := InStr(objStr, ':', , appNamePos)
                q1 := InStr(objStr, '"', , colonPos)
                q2 := InStr(objStr, '"', , q1 + 1)
                if (q1 && q2)
                    appName := SubStr(objStr, q1 + 1, q2 - q1 - 1)
            }

            ; Extract "ExecutablePath": "value"
            execPath := ""
            exePos := InStr(objStr, '"ExecutablePath"')
            if (exePos)
            {
                colonPos := InStr(objStr, ':', , exePos)
                q1 := InStr(objStr, '"', , colonPos)
                q2 := InStr(objStr, '"', , q1 + 1)
                if (q1 && q2)
                {
                    rawPath := SubStr(objStr, q1 + 1, q2 - q1 - 1)
                    ; Unescape the backslashes
                    execPath := StrReplace(rawPath, "\\", "\")
                }
            }

            if (appName && execPath)
                appRecords.Push(Map("AppName", appName, "ExecutablePath", execPath))

            objPos := objEnd + 1
        }

        if (appRecords.Length > 0)
            presets[slotKey] := appRecords
        else if (Trim(arrayContent) = "")
            presets[slotKey] := []  ; Empty slot

        currentPos := bracketEnd + 1
    }

    return presets
}

SavePresetData(data)
{
    global SkylineState

    ; Build JSON: {"Presets": {"1": [{...}, ...], "2": [...], ...}}
    slotEntries := []
    for slotKey, value in data
    {
        if (!IsObject(value) || value.Length = 0)
        {
            slotEntries.Push("`"" slotKey "`": []")
            continue
        }

        ; Serialize array of app records
        appEntries := []
        for _, appRecord in value
        {
            if (IsObject(appRecord) && appRecord.Has("AppName") && appRecord.Has("ExecutablePath"))
            {
                appName := appRecord["AppName"]
                execPath := appRecord["ExecutablePath"]
                ; Escape backslashes for JSON
                execPath := StrReplace(execPath, "\", "\\")
                appEntries.Push("{`"AppName`": `"" appName "`", `"ExecutablePath`": `"" execPath "`"}")
            }
        }

        appsJson := JoinArrayValues(appEntries, ", ")
        slotEntries.Push("`"" slotKey "`": [" appsJson "]")
    }

    presetsJson := JoinArrayValues(slotEntries, ", ")
    jsonStr := "{`"Presets`": {" presetsJson "}}"
    WriteTextFile(SkylineState["PresetsPath"], jsonStr)
}

GetTrackedAppRecords()
{
    global SkylineState
    records := []
    seen := Map()

    for _, hwnd in SkylineState["TrackedOrder"]
    {
        if (!IsValidWindow(hwnd) || !SkylineState["TrackedWindows"].Has(hwnd))
            continue

        appInfo := ExtractAppInfoFromTrackedWindow(hwnd)
        if (appInfo.Count = 0)
            continue

        normalized := NormalizePath(appInfo["ExecutablePath"])
        if (!normalized || seen.Has(normalized))
            continue

        records.Push(appInfo)
        seen[normalized] := true
    }

    return records
}

RegisterAppPath(appName, executablePath)
{
    if (!appName || !executablePath)
        return false

    registry := GetAppRegistry()
    registry[appName] := executablePath
    SaveAppRegistry(registry)

    ; Phase 4B validation: show tooltip when app is registered
    ShowStatus("Registered: " appName)
    return true
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
    appRecords := GetTrackedAppRecords()

    if (appRecords.Length = 0)
    {
        ShowStatus("No tracked apps to save")
        return
    }

    ; Phase 4C: Register each app in the registry before saving preset
    for _, appInfo in appRecords
        RegisterAppPath(appInfo["AppName"], appInfo["ExecutablePath"])

    ; Read existing presets to preserve other slots
    presetData := GetPresetData()
    
    ; Update only this slot
    presetData[slotKey] := appRecords
    
    ; Save all presets
    SavePresetData(presetData)
    
    ; Refresh list to show that apps are still tracked and persisted
    RefreshListWindow(false)
    
    ShowStatus("Saved preset " slot " (" appRecords.Length " apps)")
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
    if (entries.Length = 0)
    {
        ShowStatus("Preset " slot " empty")
        return
    }

    SkylineState["TrackedOrder"] := []
    SkylineState["TrackedWindows"] := Map()

    ; entries is now an array of Maps with AppName and ExecutablePath
    foundCount := 0
    for _, appRecord in entries
    {
        if (!IsObject(appRecord) || !appRecord.Has("ExecutablePath"))
            continue

        executablePath := appRecord["ExecutablePath"]
        appName := appRecord["AppName"]

        if (!executablePath)
            continue

        ; First, try to find if the app is already running
        hwnd := FindOpenWindowForPath(executablePath)
        if (hwnd)
        {
            if (TrackWindow(hwnd))
                foundCount += 1
            continue
        }

        ; App is not running. Try to use the saved path directly.
        if (FileExist(executablePath))
        {
            ; Path is still valid, launch it
            Run(executablePath)
            Sleep(250)
            hwnd := FindOpenWindowForPath(executablePath)
            if (hwnd && TrackWindow(hwnd))
                foundCount += 1
            continue
        }

        ; Saved path no longer exists. Ask user to locate it.
        chosenPath := BrowseForExecutable("Locate: " appName)
        if (!chosenPath)
            continue

        RegisterAppPath(appName, chosenPath)
        Run(chosenPath)
        Sleep(250)
        hwnd := FindOpenWindowForPath(chosenPath)
        if (hwnd && TrackWindow(hwnd))
            foundCount += 1
    }

    RefreshListWindow(false)
    ShowStatus("Activated preset " slot " (" foundCount " apps)")
}

ClearTrackedWindows(showNotice := true)
{
    global SkylineState
    SkylineState["TrackedOrder"] := []
    SkylineState["TrackedWindows"] := Map()

    if (showNotice)
        ShowStatus("Cleared tracked windows")
}

EnsureDataFiles()

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
