#Requires AutoHotkey v2.0
#SingleInstance Force

; Placeholder script for the separate Skyline utility.
; This file is intentionally minimal for now and will be expanded later.

^!t::
{
    ToolTip("Skyline tracking is not implemented yet")
    SetTimer(() => ToolTip(), -1200)
}

^!+t::
{
    ToolTip("Skyline untrack is not implemented yet")
    SetTimer(() => ToolTip(), -1200)
}

^!l::
{
    MsgBox("Skyline list view is not implemented yet.", "Skyline")
}
