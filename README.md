# AutoHotkey v2 Script Library

A centralized repository for personal AutoHotkey v2 scripts, designed to stay synchronized and run automatically across multiple devices via Windows Startup.

---

## Prerequisites
* **Windows 10 / 11**
* *Note: If AutoHotkey v2 is not installed, running `Setup.bat` will automatically download and install it for you.*

---

## First-Time Setup on a New PC
1. **Clone or download** this repository to your computer.
2. Double-click `Setup.bat` (or run `.\Setup.bat` in Terminal).
3. Done! All scripts inside `Scripts/` (including subfolders) will launch immediately and run on every boot.

---

## Adding New Scripts
* Save any `.ahk` file inside the `Scripts/` directory or subfolders.
* Double-click `MasterLauncher.ahk` or reboot your PC to launch new additions.

---

## Repository Structure
* `.gitattributes` — Git configuration file.
* `README.md` — Repository documentation and setup instructions.
* `Setup.bat` — One-time setup script that installs AHK v2 (if needed) and links the launcher to Windows Startup.
* `MasterLauncher.ahk` — Auto-generated launcher executed on boot to run your scripts.
* `Scripts/` — Folder containing all active AutoHotkey scripts.