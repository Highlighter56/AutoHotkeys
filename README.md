# AutoHotkey v2 Script Library

A centralized repository for personal AutoHotkey v2 scripts, designed to stay synchronized and run automatically across multiple devices via Windows Startup.

---

## Prerequisites
* **Windows 10 / 11**
* *Note: If AutoHotkey v2 is not installed, running `Setup.bat` will automatically download and install it for you.*

---

## First-Time Setup on a New PC
1. **Clone or download** this repository to your computer.
2. Run `Setup.bat` (Either through the terminal with  `.\Setup.bat`, or Double-click the file to run).
3. Your Done! All scripts inside `Scripts/` (including subfolders) will launch immediately and run on every boot.

---

## Adding New Scripts
* Save any `.ahk` file inside the `Scripts/` directory or subfolders.
* Run `MasterLauncher.ahk` or reboot your PC to launch new scripts that are added after boot.

---

## Repository Structure
* `.gitattributes` — Git configuration file.
* `README.md` — Repository documentation and setup instructions.
* `Setup.bat` — One-time setup script that installs AHK v2 (if needed) and links the launcher to Windows Startup.
* `MasterLauncher.ahk` — Auto-generated launcher executed on boot to run your scripts.
* `Scripts/` — Folder containing all active AutoHotkey scripts.

---

## AutoHotkey Descriptions
### `MinimizeAndRestoreActiveWindow.ahk`
- `Ctrl + Alt + M` - Minimize the active window and remember it for later.
- `Ctrl + Alt + R` - Restore and activate the previously minimized window, preserving its maximized or normal state.

- The script remembers one window at a time, allowing you to switch to another app and return to the minimized window when you are ready.