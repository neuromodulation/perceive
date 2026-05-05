# perceive_gui_startup Deployment

## End-user license requirement
End users **do not need a MATLAB license**. They only need the matching MATLAB Runtime.

## Quick start (for users)
1. Double-click `run_perceive_gui_startup.bat` (Windows), or run `./run_perceive_gui_startup.sh` (macOS/Linux).
2. If Runtime is missing, the launcher can offer to start a bundled local installer (`MCRInstaller.exe` on Windows or `install` on macOS/Linux) when available.
3. Install **MATLAB Runtime R2023a or newer**, then run the same launcher again.

## Required runtime
This app accepts **MATLAB Runtime R2023a or newer**.

Download: [MATLAB Runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html)

## Platform support in this folder
- Windows: `perceive_gui_startup.exe` + `run_perceive_gui_startup.bat`
- macOS/Linux: requires a separately built artifact for that OS

MATLAB Compiler outputs are OS-specific. A Windows `.exe` will not run on macOS/Linux.

## Run instructions
- Windows: double-click `run_perceive_gui_startup.bat`
- macOS/Linux: run `./run_perceive_gui_startup.sh` after building and packaging the app on that OS
- Optional runtime override:
  - Windows: `run_perceive_gui_startup.bat --runtime-path "C:\Path\To\MATLAB Runtime\R2024b"`
  - macOS/Linux: `./run_perceive_gui_startup.sh --runtime-path /path/to/MATLAB_Runtime_R2024b`

## Troubleshooting log
Both launchers write a lightweight `runtime_check.log` file in the launcher folder.
Use it for support tickets to see runtime detection and launcher decisions.

## Build for each OS
Build on the target OS (Windows, macOS, Linux) using MATLAB Compiler, then ship that OS artifact with its launcher.

## Clean Windows download folder
To prepare a user-facing Windows bundle in one place, run in MATLAB:

`prepare_windows_release_folder`

This fills:

`release/windows/perceive_gui_startup`
