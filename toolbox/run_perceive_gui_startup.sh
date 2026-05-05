#!/bin/bash
set -euo pipefail

MIN_RUNTIME_YEAR=2023
RUNTIME_LABEL="R2023a or newer"
RUNTIME_URL="https://www.mathworks.com/products/compiler/matlab-runtime.html"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/runtime_check.log"
CUSTOM_RUNTIME_PATH=""

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

usage() {
    echo "Usage: ./run_perceive_gui_startup.sh [--runtime-path /path/to/MATLAB_Runtime_R2023a-or-newer]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --runtime-path)
            [[ $# -ge 2 ]] || { echo "[perceive] Missing value for --runtime-path"; exit 2; }
            CUSTOM_RUNTIME_PATH="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "[perceive] Unknown argument: $1"
            usage
            exit 2
            ;;
    esac
done

log "Launcher started"
[[ -n "$CUSTOM_RUNTIME_PATH" ]] && log "Custom runtime path requested: $CUSTOM_RUNTIME_PATH"

if [[ "$OSTYPE" == darwin* ]]; then
    OS="macOS"
    APP_PATH="$SCRIPT_DIR/perceive_gui_startup.app"
    echo "Detected OS: macOS"
elif [[ "$OSTYPE" == linux-gnu* ]]; then
    OS="Linux"
    APP_PATH="$SCRIPT_DIR/perceive_gui_startup"
    echo "Detected OS: Linux"
else
    echo "Error: Unsupported OS. This script only works on macOS and Linux."
    exit 1
fi

if [[ ! -e "$APP_PATH" ]]; then
    echo "[perceive] Platform app artifact is missing:"
    echo "  $APP_PATH"
    echo "This package may only contain the Windows .exe."
    echo "Build and package perceive_gui_startup for $OS, then try again."
    exit 1
fi

runtime_detected=0
runtime_hint=""
runtime_version=""

accept_runtime_path() {
    local p="$1"
    local b
    local y
    b="$(basename "$p")"
    if [[ "$b" =~ ^R([0-9]{4})([ab])$ ]]; then
        y="${BASH_REMATCH[1]}"
        if (( y >= MIN_RUNTIME_YEAR )); then
            runtime_detected=1
            runtime_hint="$p"
            runtime_version="$b"
            return 0
        fi
    elif [[ "$b" =~ ^MATLAB_Runtime_R([0-9]{4})([ab])$ ]]; then
        y="${BASH_REMATCH[1]}"
        if (( y >= MIN_RUNTIME_YEAR )); then
            runtime_detected=1
            runtime_hint="$p"
            runtime_version="R${y}${BASH_REMATCH[2]}"
            return 0
        fi
    fi
    return 1
}

scan_root_for_runtime_dirs() {
    local root="$1"
    local d
    [[ -d "$root" ]] || return 0
    for d in "$root"/R????[ab] "$root"/MATLAB_Runtime_R????[ab]; do
        [[ -d "$d" ]] || continue
        accept_runtime_path "$d" && return 0
    done
    return 0
}

detect_runtime() {
    runtime_detected=0
    runtime_hint=""
    runtime_version=""

    if [[ -n "$CUSTOM_RUNTIME_PATH" && -d "$CUSTOM_RUNTIME_PATH" ]]; then
        if accept_runtime_path "$CUSTOM_RUNTIME_PATH"; then return; fi
    fi

    if [[ -n "${MCRROOT:-}" && -d "${MCRROOT}" ]]; then
        if accept_runtime_path "${MCRROOT}"; then return; fi
    fi

    if [[ "$OS" == "macOS" ]]; then
        scan_root_for_runtime_dirs "/Applications/MATLAB/MATLAB_Runtime"
        [[ "$runtime_detected" -eq 1 ]] && return
        scan_root_for_runtime_dirs "/Applications/MATLAB"
        [[ "$runtime_detected" -eq 1 ]] && return
        scan_root_for_runtime_dirs "${HOME}/MATLAB"
        [[ "$runtime_detected" -eq 1 ]] && return
    else
        scan_root_for_runtime_dirs "/usr/local/MATLAB/MATLAB_Runtime"
        [[ "$runtime_detected" -eq 1 ]] && return
        scan_root_for_runtime_dirs "/usr/local/MATLAB"
        [[ "$runtime_detected" -eq 1 ]] && return
        scan_root_for_runtime_dirs "${HOME}/MATLAB"
        [[ "$runtime_detected" -eq 1 ]] && return
    fi
}

echo "Checking for MATLAB Runtime ${RUNTIME_LABEL}..."
detect_runtime
if [[ "$runtime_detected" -eq 0 ]]; then
    echo "[perceive] MATLAB Runtime ${RUNTIME_LABEL} is required but not detected."
    log "Runtime missing before installer flow"
    echo
    if [[ -x "$SCRIPT_DIR/install" ]]; then
        read -r -p "Found local installer script 'install'. Start it now? [y/N]: " install_now
        if [[ "$install_now" =~ ^[Yy]$ ]]; then
            echo "Starting local installer..."
            "$SCRIPT_DIR/install" || true
            detect_runtime
            if [[ "$runtime_detected" -eq 1 ]]; then
                log "Runtime detected after local installer: $runtime_version at $runtime_hint"
            else
                log "Runtime still missing after local installer"
            fi
        fi
    fi

    if [[ "$runtime_detected" -eq 0 ]]; then
        echo "Opening the official Runtime download page..."
        if [[ "$OS" == "macOS" ]]; then
            open "$RUNTIME_URL"
        elif [[ "$OS" == "Linux" ]]; then
            xdg-open "$RUNTIME_URL" || sensible-browser "$RUNTIME_URL" || true
        fi
        echo "Install MATLAB Runtime ${RUNTIME_LABEL}, then run this launcher again."
        log "Opened download page and exited (runtime missing)"
        exit 1
    fi
fi

echo "[perceive] MATLAB Runtime ${runtime_version} detected at: ${runtime_hint}"
echo "[perceive] Starting app..."
log "Runtime detected: ${runtime_version} at ${runtime_hint}"
if [[ "$OS" == "macOS" ]]; then
    open "$APP_PATH"
    log "Launched macOS app bundle"
else
    chmod +x "$APP_PATH"
    set +e
    "$APP_PATH"
    app_exit=$?
    set -e
    log "Linux app exited with code ${app_exit}"
    exit $app_exit
fi
