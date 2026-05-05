@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"
set "RUNTIME_URL=https://www.mathworks.com/products/compiler/matlab-runtime.html"
set "MIN_RUNTIME_YEAR=2023"
set "RUNTIME_LABEL=R2023a or newer"
set "MATLAB_RUNTIME_INSTALLED=0"
set "RUNTIME_FOUND_PATH="
set "RUNTIME_FOUND_VERSION="
set "CUSTOM_RUNTIME_PATH="
set "LOG_FILE=%~dp0runtime_check.log"
set "DETECT_SCRIPT=%~dp0detect_matlab_runtime_windows.ps1"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--runtime-path" (
    if "%~2"=="" (
        echo [perceive] Missing value for --runtime-path
        exit /b 2
    )
    set "CUSTOM_RUNTIME_PATH=%~2"
    shift
    shift
    goto parse_args
)
if /I "%~1"=="--help" (
    echo Usage: run_perceive_gui_startup.bat [--runtime-path "C:\Path\To\MATLAB Runtime\R2023a-or-newer"]
    exit /b 0
)
echo [perceive] Unknown argument: %~1
echo Use --help for usage.
exit /b 2
:args_done

call :log "Launcher started"
if defined CUSTOM_RUNTIME_PATH call :log "Custom runtime path requested: %CUSTOM_RUNTIME_PATH%"

if not exist "perceive_gui_startup.exe" (
    echo.
    echo [perceive] App file not found: perceive_gui_startup.exe
    echo Please keep this launcher in the same folder as the app, then try again.
    echo.
    pause
    exit /b 1
)

call :detect_runtime

if !MATLAB_RUNTIME_INSTALLED! EQU 0 (
    echo.
    echo [perceive] MATLAB Runtime %RUNTIME_LABEL% is required but not detected.
    echo.
    if exist "MCRInstaller.exe" (
        echo A local MATLAB Runtime installer was found: MCRInstaller.exe
        set /p INSTALL_NOW=Start installer now? [Y/N]:
        if /I "!INSTALL_NOW!"=="Y" (
            echo Starting MATLAB Runtime installer with admin prompt if required...
            start /wait "" "MCRInstaller.exe"
            echo Re-checking MATLAB Runtime installation...
            call :detect_runtime
            if !MATLAB_RUNTIME_INSTALLED! EQU 1 (
                echo MATLAB Runtime !RUNTIME_FOUND_VERSION! detected after installer. Continuing...
                call :log "Runtime detected after local installer: !RUNTIME_FOUND_VERSION! at !RUNTIME_FOUND_PATH!"
                goto run_app
            )
            echo Runtime still not detected. You may need to complete installer steps or reboot.
            call :log "Runtime not detected after local installer"
        )
    )
    echo.
    echo Opening official MATLAB Runtime download page...
    echo %RUNTIME_URL%
    start "" "%RUNTIME_URL%"
    echo Install MATLAB Runtime %RUNTIME_LABEL%, then run this launcher again.
    call :log "Runtime missing. Opened download page and exited."
    pause
    exit /b 1
)

:: If MATLAB Runtime is installed, run the application
:run_app
echo [perceive] MATLAB Runtime !RUNTIME_FOUND_VERSION! detected. Starting app...
echo [perceive] Runtime location: !RUNTIME_FOUND_PATH!
call :log "Runtime detected: !RUNTIME_FOUND_VERSION! at !RUNTIME_FOUND_PATH!"
perceive_gui_startup.exe
set EXITCODE=%ERRORLEVEL%
echo.
echo [perceive] App exited with code %EXITCODE%.
call :log "App exited with code %EXITCODE%"
pause
exit /b %EXITCODE%

:detect_runtime
set "MATLAB_RUNTIME_INSTALLED=0"
set "RUNTIME_FOUND_PATH="
set "RUNTIME_FOUND_VERSION="
set "DETECT_RESULT="

if not exist "%DETECT_SCRIPT%" (
    call :log "Runtime detection script missing: %DETECT_SCRIPT%"
    exit /b 0
)

for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECT_SCRIPT%" -MinYear %MIN_RUNTIME_YEAR% -CustomRuntimePath "%CUSTOM_RUNTIME_PATH%"`) do (
    set "DETECT_RESULT=%%A"
)

if not defined DETECT_RESULT exit /b 0

for /f "tokens=1,2,3 delims=|" %%A in ("!DETECT_RESULT!") do (
    if /I "%%A"=="FOUND" (
        set "MATLAB_RUNTIME_INSTALLED=1"
        set "RUNTIME_FOUND_VERSION=%%B"
        set "RUNTIME_FOUND_PATH=%%C"
    )
)
exit /b 0

:log
echo [%date% %time%] %~1>>"%LOG_FILE%"
exit /b 0
