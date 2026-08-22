# AutoHotkey v2 Script Library

A centralized repository for personal AutoHotkey v2 scripts, designed to stay synchronized and run automatically across multiple devices via Windows Startup.

---

## Prerequisites
* **Windows 10 / 11**
* **AutoHotkey v2**
  * *Note: If AHK v2 is not installed, running `Setup.ahk` will automatically detect this and direct you to download it.*

---

## First-Time Setup on a New PC
1. **Clone or download** this repository to your preferred local folder.
2. Run `Setup.ahk` by double-clicking it.
3. Done! All scripts inside `Scripts/` (including any subfolders) will launch immediately and run automatically on every system boot.

---

## Adding New Scripts
* Simply save any `.ahk` file inside the `Scripts/` directory or any subfolder within it.
* Double-click `MasterLauncher.ahk` or reboot your PC to launch any newly added scripts.

---

## Repository Structure
* `.gitattributes` — Git configuration file.
* `README.md` — Repository documentation and setup instructions.
* `Setup.ahk` — One-time setup script that links the launcher to your Windows Startup folder.
* `MasterLauncher.ahk` — Auto-generated launcher executed on boot to run your scripts.
* `Scripts/` — Folder containing all active AutoHotkey scripts and organized subfolders.