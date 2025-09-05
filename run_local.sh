#!/usr/bin/env bash
# run_local.sh
# One-shot local bootstrap for FoodScanner API:
# - Creates/activates venv
# - Installs runtime + dev deps
# - Runs tests
# - Starts the FastAPI server
# - Performs a health check
# - Prints a clear "app is up" message
#
# Usage:
#   bash run_local.sh
#
# Optional env vars:
#   APP_MODULE="backend.api:app"   # Change if your FastAPI app lives elsewhere
#   HOST="127.0.0.1"
#   PORT="8000"
#   REQUIREMENTS_FILE="requirements.txt"
#   DEV_REQUIREMENTS_FILE="requirements-dev.txt"
#   VENV_DIR=".venv"

set -euo pipefail

### ----------------------------
### Config (with sensible defaults)
### ----------------------------
APP_MODULE="${APP_MODULE:-backend.api:app}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-requirements.txt}"
DEV_REQUIREMENTS_FILE="${DEV_REQUIREMENTS_FILE:-requirements-dev.txt}"
VENV_DIR="${VENV_DIR:-.venv}"
HEALTH_TIMEOUT_SECONDS="${HEALTH_TIMEOUT_SECONDS:-45}"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

step() { echo -e "${BOLD}› $*${RESET}"; }
info() { echo -e "${DIM}$*${RESET}"; }
ok()   { echo -e "${GREEN}✔ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }
err()  { echo -e "${RED}✖ $*${RESET}"; }

### ----------------------------
### Helpers
### ----------------------------
need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Missing required command: $1"
        exit 1
    fi
}

detect_python() {
    if command -v python >/dev/null 2>&1; then
        echo "python"
        elif command -v python3 >/dev/null 2>&1; then
        echo "python3"
    else
        err "Python not found. Please install Python 3.11+"
        exit 1
    fi
}

activate_venv() {
    # POSIX layout
    if [ -f "${VENV_DIR}/bin/activate" ]; then
        # shellcheck disable=SC1090
        source "${VENV_DIR}/bin/activate"
        return
    fi
    # Windows venv layout (Git Bash)
    if [ -f "${VENV_DIR}/Scripts/activate" ]; then
        # shellcheck disable=SC1090
        source "${VENV_DIR}/Scripts/activate"
        return
    fi
    err "Unable to find venv activation script in ${VENV_DIR}."
    exit 1
}

wait_for_http() {
    local url="$1"
    local timeout="$2"
    local start ts code
    start="$(date +%s)"
    while :; do
        if code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)"; then
            # consider 2xx/3xx as OK
            if [[ "$code" =~ ^2[0-9]{2}$ || "$code" =~ ^3[0-9]{2}$ ]]; then
                return 0
            fi
        fi
        ts="$(date +%s)"
        if (( ts - start >= timeout )); then
            return 1
        fi
        sleep 1
    done
}

### ----------------------------
### Pre-flight checks
### ----------------------------
step "Checking required tools"
need_cmd curl
PY="$(detect_python)"
ok "Using Python: $($PY -V 2>&1)"

### ----------------------------
### Create and activate virtual environment
### ----------------------------
step "Setting up virtual environment: ${VENV_DIR}"
if [ ! -d "${VENV_DIR}" ]; then
    "$PY" -m venv "${VENV_DIR}"
    ok "Created venv at ${VENV_DIR}"
else
    info "Venv already exists at ${VENV_DIR}"
fi
activate_venv
ok "Activated venv"

### ----------------------------
### Upgrade pip/setuptools/wheel
### ----------------------------
step "Upgrading pip, setuptools, and wheel"
pip install --upgrade pip setuptools wheel >/dev/null
ok "Upgraded packaging tools"

### ----------------------------
### Install dependencies
### ----------------------------
step "Resolving requirements files"

resolve_file() {
    local primary="$1"
    local fallback_dir="$2"
    if [ -f "$primary" ]; then
        echo "$primary"
        elif [ -f "${fallback_dir}/$(basename "$primary")" ]; then
        echo "${fallback_dir}/$(basename "$primary")"
    else
        echo ""  # not found
    fi
}

# Ensure we're running relative to the script location (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REQ_FILE_RESOLVED="$(resolve_file "${REQUIREMENTS_FILE}" "backend")"
DEV_REQ_FILE_RESOLVED="$(resolve_file "${DEV_REQUIREMENTS_FILE}" "backend")"

step "Installing runtime dependencies from ${REQ_FILE_RESOLVED:-<none>}"
if [ -n "$REQ_FILE_RESOLVED" ]; then
    pip install -r "$REQ_FILE_RESOLVED"
    ok "Runtime dependencies installed"
else
    warn "No requirements file found (checked: ${REQUIREMENTS_FILE} and backend/$(basename "$REQUIREMENTS_FILE")). Skipping."
fi

step "Installing dev dependencies from ${DEV_REQ_FILE_RESOLVED:-<none>}"
if [ -n "$DEV_REQ_FILE_RESOLVED" ]; then
    pip install -r "$DEV_REQ_FILE_RESOLVED"
    ok "Dev dependencies installed"
else
    warn "No dev requirements file found (checked: ${DEV_REQUIREMENTS_FILE} and backend/$(basename "$DEV_REQUIREMENTS_FILE")). Skipping."
fi


### ----------------------------
### Ensure backend is a package
### ----------------------------
if [ -d "backend" ] && [ ! -f "backend/__init__.py" ]; then
    step "Creating backend/__init__.py so imports work"
    printf "" > backend/__init__.py
    ok "backend/__init__.py created"
fi

### ----------------------------
### Run tests
### ----------------------------
step "Running test suite"
if ! "$PY" -m pytest -q; then
    err "Tests failed. Aborting."
    exit 1
fi
ok "All tests passed"

### ----------------------------
### Start server (background)
### ----------------------------
step "Starting FastAPI server (${APP_MODULE}) on ${HOST}:${PORT}"

LOG_FILE="${LOG_FILE:-/tmp/foodscanner_uvicorn.log}"
LIVE_LOGS="${LIVE_LOGS:-0}"

# Start Uvicorn and write logs to file
# (append so multiple runs keep history; switch to '>' if you prefer truncation)
"$PY" -m uvicorn "${APP_MODULE}" --host "${HOST}" --port "${PORT}" --log-level info >>"$LOG_FILE" 2>&1 &
UV_PID=$!
ok "Uvicorn started with PID ${UV_PID}"
info "Logs: ${LOG_FILE}"

# If live logs requested, tail in background so you see traces in this terminal
if [ "$LIVE_LOGS" = "1" ]; then
  info "LIVE_LOGS=1 → streaming logs here (Ctrl+C stops tail, server keeps running)"
  tail -n +1 -f "$LOG_FILE" &
  TAIL_PID=$!
fi


### ----------------------------
### Health check
### ----------------------------
API_BASE="http://${HOST}:${PORT}"
HEALTH_URLS=(
    "${API_BASE}/health"
    "${API_BASE}/docs"
    "${API_BASE}/"
)

step "Performing health check (timeout: ${HEALTH_TIMEOUT_SECONDS}s)"
HC_OK=1
for url in "${HEALTH_URLS[@]}"; do
    info "Checking ${url}"
    if wait_for_http "${url}" "${HEALTH_TIMEOUT_SECONDS}"; then
        ok "Healthy endpoint detected at: ${url}"
        HC_OK=0
        break
    fi
done

if [ $HC_OK -ne 0 ]; then
    err "Health check failed. See log at /tmp/foodscanner_uvicorn.log"
    # Keep server running for debugging; if you prefer auto-stop on failure, uncomment:
    # kill "${UV_PID}" || true
    exit 1
fi

### ----------------------------
### Final status
### ----------------------------
echo
echo -e "${GREEN}${BOLD}🎉 The FoodScanner API is UP and RUNNING!${RESET}"
echo -e "   ${BOLD}Base URL:${RESET} ${API_BASE}"
echo -e "   ${BOLD}Interactive docs:${RESET} ${API_BASE}/docs"
echo -e "   ${BOLD}Process PID:${RESET} ${UV_PID}"
echo -e "   ${BOLD}To stop the server:${RESET} kill ${UV_PID}"
echo
