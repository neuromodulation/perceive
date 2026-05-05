#!/bin/bash
set -euo pipefail

RUNTIME_VERSION="R2026a"
RUNTIME_URL="https://www.mathworks.com/products/compiler/matlab-runtime.html"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/runtime_check.log"
CUSTOM_RUNTIME_PATH=""

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

usage() {
    echo "Usage: ./run_perceive_gui_startup.sh [--runtime-path /path/to/MATLAB_Runtime_R2026a]"
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

# Detect OS and expected artifact/runtime layout
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
detect_runtime() {
    runtime_detected=0
    runtime_hint=""

    if [[ -n "$CUSTOM_RUNTIME_PATH" && -d "$CUSTOM_RUNTIME_PATH" ]]; then
        runtime_detected=1
        runtime_hint="$CUSTOM_RUNTIME_PATH"
        return
    fi

    if [[ -n "${MCRROOT:-}" && -d "${MCRROOT}" ]]; then
        runtime_detected=1
        runtime_hint="${MCRROOT}"
        return
    fi

    if [[ "$OS" == "macOS" ]]; then
        for p in \
            "/Applications/MATLAB/MATLAB_Runtime_${RUNTIME_VERSION}" \
            "/Applications/MATLAB/MATLAB_Runtime/${RUNTIME_VERSION}" \
            "/Applications/MATLAB/MATLAB_Runtime/v${RUNTIME_VERSION#R}"; do
            if [[ -d "$p" ]]; then
                runtime_detected=1
                runtime_hint="$p"
                return
            fi
        done
    else
        for p in \
            "/usr/local/MATLAB/MATLAB_Runtime_${RUNTIME_VERSION}" \
            "/usr/local/MATLAB/MATLAB_Runtime/${RUNTIME_VERSION}" \
            "/usr/local/MATLAB/MATLAB_Runtime/v${RUNTIME_VERSION#R}" \
            "${HOME}/MATLAB/MATLAB_Runtime_${RUNTIME_VERSION}"; do
            if [[ -d "$p" ]]; then
                runtime_detected=1
                runtime_hint="$p"
                return
            fi
        done
    fi
}

echo "Checking for MATLAB Runtime ${RUNTIME_VERSION}..."
detect_runtime
if [[ "$runtime_detected" -eq 0 ]]; then
    echo "[perceive] MATLAB Runtime ${RUNTIME_VERSION} is required but not detected."
    log "Runtime missing before installer flow"
    echo
    if [[ -x "$SCRIPT_DIR/install" ]]; then
        read -r -p "Found local installer script 'install'. Start it now? [y/N]: " install_now
        if [[ "$install_now" =~ ^[Yy]$ ]]; then
            echo "Starting local installer..."
            "$SCRIPT_DIR/install" || true
            detect_runtime
            if [[ "$runtime_detected" -eq 1 ]]; then
                log "Runtime detected after local installer: $runtime_hint"
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
        echo "Install Runtime ${RUNTIME_VERSION}, then run this launcher again."
        log "Opened download page and exited (runtime missing)"
        exit 1
    fi
fi

echo "[perceive] MATLAB Runtime ${RUNTIME_VERSION} detected at: ${runtime_hint}"
echo "[perceive] Starting app..."
log "Runtime detected: ${runtime_hint}"
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
