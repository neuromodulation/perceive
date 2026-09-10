Perceive Install Folder (Flat, No Subfolders)

This folder is intentionally flat.
Do not create nested release subfolders.

Runtime requirement (all platforms):
- MATLAB Runtime R2023a or newer
- No MATLAB license required for end users

One compiled application entry point: perceive
- Double-click / launcher with no arguments opens the startup GUI.
- Command line: pass JSON paths and options as before (advanced use).

Launchers (MATLAB Runtime only — consistent naming):
- Windows:   perceive_no_license_windows.bat
- macOS:     perceive_no_license_macOS.sh
- Linux:     perceive_no_license_linux.sh

-----------------------------------
Windows
-----------------------------------
Files for the GUI + Runtime check:
- perceive.exe
- perceive_no_license_windows.bat  (optional but recommended)
- detect_matlab_runtime_windows.ps1

Optional:
- MCRInstaller.exe (offline/local Runtime installer)

How to run on Windows:
1) Double-click perceive_no_license_windows.bat, or double-click perceive.exe
2) If Runtime is missing, follow prompts
3) Re-run the same launcher

Advanced (Command Prompt):
  perceive.exe
  perceive.exe "C:\path\Report_Json_Session_Report_....json"
  perceive.exe start

-----------------------------------
macOS
-----------------------------------
- perceive.app
- perceive_no_license_macOS.sh

How to run:
1) Open Terminal in this folder
2) chmod +x perceive_no_license_macOS.sh
3) ./perceive_no_license_macOS.sh

Advanced:
  open perceive.app
  ./perceive /path/to/file.json

-----------------------------------
Linux
-----------------------------------
- perceive  (ELF binary)
- perceive_no_license_linux.sh

How to run:
1) Open Terminal in this folder
2) chmod +x perceive_no_license_linux.sh
3) ./perceive_no_license_linux.sh

Advanced:
  ./perceive
  ./perceive /path/to/file.json

-----------------------------------
MATLAB (source toolbox)
-----------------------------------
  perceive                    (batch: cwd JSON / file picker)
  perceive start              (startup GUI)
  perceive('myfile.json','21', ...)

Troubleshooting:
- runtime_check.log is created next to the launcher
- share runtime_check.log for support
