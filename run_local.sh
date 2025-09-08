#!/usr/bin/env bash
# run_local.sh
# Local bootstrap for FoodScanner API:
# - Loads .env (if present) and exports sane defaults for login+DB
# - Creates/activates venv
# - Installs deps (runtime + dev)
# - Spins up a local Postgres in Docker (DEV only, unless SKIP_LOCAL_DB=1)
# - Runs tests (skips live OCR by default; toggle via SKIP_OCR_LIVE=0)
# - (Optional) runs Alembic migrations if present
# - Starts FastAPI (backend.api:app)
# - Health check on /health
# - Optional live logs streaming (LIVE_LOGS=1)

# Make pip deterministic/non-interactive
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_INPUT=1
export PIP_DEFAULT_TIMEOUT="${PIP_DEFAULT_TIMEOUT:-60}"

set -euo pipefail

### ----------------------------
### Config (defaults)
### ----------------------------
APP_MODULE="${APP_MODULE:-backend.api:app}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"

REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-backend/requirements.txt}"
DEV_REQUIREMENTS_FILE="${DEV_REQUIREMENTS_FILE:-backend/requirements-dev.txt}"
VENV_DIR="${VENV_DIR:-.venv}"
HEALTH_TIMEOUT_SECONDS="${HEALTH_TIMEOUT_SECONDS:-45}"
LOG_FILE="${LOG_FILE:-/tmp/foodscanner_uvicorn.log}"
DEV_MODE="${DEV_MODE:-1}"                 # default dev on local
SKIP_DEV_DEPS="${SKIP_DEV_DEPS:-0}"       # set to 1 to skip dev deps

# Dependency logging controls
DEPS_LOG_FILE="${DEPS_LOG_FILE:-/tmp/foodscanner_deps.log}"
DEPS_VERBOSE="${DEPS_VERBOSE:-1}"     # 0=silent, 1=verbose (-v), 2=very verbose (-vv)
LIVE_LOGS="${LIVE_LOGS:-0}"

# Policy (prefers v2; falls back to v1)
POLICY_DIR="${POLICY_DIR:-backend/policies}"
POLICY_FILE="${POLICY_FILE:-policy_v2.json}"

# Auth / DB env for login feature
JWT_SECRET="${JWT_SECRET:-dev-please-change-me}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-foodscanner}"
DB_USER="${DB_USER:-foodscanner}"
DB_PASS="${DB_PASS:-dev-password}"

# Local DB controls
SKIP_LOCAL_DB="${SKIP_LOCAL_DB:-0}"       # set to 1 to not start Docker PG
PG_IMAGE="${PG_IMAGE:-postgres:16-alpine}"
PG_CONTAINER="${PG_CONTAINER:-foodscanner-pg}"

# Tests
SKIP_OCR_LIVE="${SKIP_OCR_LIVE:-1}"       # default skip live OCR
PYTEST_ADDOPTS="${PYTEST_ADDOPTS:-}"

BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32m'; RED='\033[31m'; YELLOW='\033[33m'; RESET='\033[0m'
step() { echo -e "${BOLD}› $*${RESET}"; }
info() { echo -e "${DIM}$*${RESET}"; }
ok()   { echo -e "${GREEN}✔ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }
err()  { echo -e "${RED}✖ $*${RESET}"; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }; }

detect_python() {
  if command -v python >/dev/null 2>&1; then echo "python";
  elif command -v python3 >/dev/null 2>&1; then echo "python3";
  else err "Python not found. Please install Python 3.11+"; exit 1; fi
}

activate_venv() {
  if [ -f "${VENV_DIR}/bin/activate" ]; then
    # shellcheck disable=SC1090
    source "${VENV_DIR}/bin/activate"; return
  fi
  if [ -f "${VENV_DIR}/Scripts/activate" ]; then
    # shellcheck disable=SC1090
    source "${VENV_DIR}/Scripts/activate"; return
  fi
  err "Unable to find venv activation script in ${VENV_DIR}."
  exit 1
}

wait_for_http() {
  local url="$1" timeout="$2" start ts code
  start="$(date +%s)"
  while :; do
    if code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)"; then
      [[ "$code" =~ ^2[0-9]{2}$ || "$code" =~ ^3[0-9]{2}$ ]] && return 0
    fi
    ts="$(date +%s)"
    (( ts - start >= timeout )) && return 1
    sleep 1
  done
}

resolve_file() {
  local primary="$1"
  if [ -f "$primary" ]; then echo "$primary"
  elif [ -f "backend/$(basename "$primary")" ]; then echo "backend/$(basename "$primary")"
  else echo ""; fi
}

is_windows() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *)                     return 1 ;;
  esac
}

compute_dep_logs() {
  PIP_LOG="${DEPS_LOG_FILE:-/tmp/foodscanner_deps.log}"
  TEE_LOG="${DEPS_LOG_FILE:-/tmp/foodscanner_deps.log}"
  if is_windows; then
    command -v cygpath >/dev/null 2>&1 && {
      PIP_LOG="$(cygpath -w "$PIP_LOG")"  # C:\Users\...\pip_deps.log
      TEE_LOG="$(cygpath -u "$TEE_LOG")"  # /c/Users/...\pip_deps.log
    }
  fi
  mkdir -p "$(dirname "$TEE_LOG")" 2>/dev/null || true
}


has_docker() {
  command -v docker >/dev/null 2>&1 || return 1
  docker info >/dev/null 2>&1 || return 1
  return 0
}

start_local_pg() {
  local cname="${PG_CONTAINER}"
  if docker ps --format '{{.Names}}' | grep -q "^${cname}$"; then
    info "Postgres container ${cname} already running."
    return 0
  fi
  if docker ps -a --format '{{.Names}}' | grep -q "^${cname}$"; then
    step "Starting existing Postgres container ${cname}"
    docker start "${cname}" >/dev/null
  else
    step "Running new Postgres container ${cname} (${PG_IMAGE})"
    docker run -d --name "${cname}" \
      -e POSTGRES_DB="${DB_NAME}" \
      -e POSTGRES_USER="${DB_USER}" \
      -e POSTGRES_PASSWORD="${DB_PASS}" \
      -p "${DB_PORT}:5432" \
      "${PG_IMAGE}" >/dev/null
  fi
  ok "Postgres container is up"
}

wait_for_pg_container() {
  local cname="${PG_CONTAINER}"
  step "Waiting for Postgres to become ready"
  if ! docker exec "${cname}" sh -lc 'for i in $(seq 1 60); do pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" && exit 0; sleep 1; done; exit 1'; then
    err "Postgres in container did not become ready within 60s"
    exit 1
  fi
  ok "Postgres is ready"
}

# Windows reqs massager:
# - Rebase -r/--requirement paths to absolute (and convert /c/... -> C:/...)
# - Drop psycopg2 / psycopg2-binary (any pins/markers)
# - Ensure psycopg[binary] >= 3.1.19 (wheels for Python 3.13)
prepare_win_requirements() {
  local in="$1" out="$2"; [[ -z "$in" || ! -f "$in" ]] && return 1
  local basedir; basedir="$(cd "$(dirname "$in")" && pwd)"
  awk -v base="$basedir" '
    function is_abs_win(p) { return (p ~ /^[A-Za-z]:[\/\\]/) }
    function is_abs_unix(p){ return (p ~ /^\//) }
    function msys_to_win(p,   drv, rest) {
      if (p ~ /^\/[A-Za-z]\//) { drv = substr(p,2,1); rest = substr(p,3); return toupper(drv) ":" rest }
      return p
    }
    function abs_path(p,   j) {
      if (is_abs_win(p) || is_abs_unix(p)) return msys_to_win(p)
      if (base ~ /\/$/) j = base p; else j = base "/" p
      return msys_to_win(j)
    }
    BEGIN { have_v3 = 0 }
    {
      line = $0

      # Convert at most ONE short include (-r/-c) per line to avoid infinite loops.
      # If the include is already absolute, skip rewriting.
      if (match(line, /(^|[[:space:]])-(r|c)[[:space:]]+([^[:space:]]+)/, m)) {
        inc = m[3]; abs = abs_path(inc)
        if (abs != inc) {
          pre = substr(line, 1, RSTART-1)
          post = substr(line, RSTART+RLENGTH)
          line = pre sprintf("%s-%s %s", m[1], m[2], abs) post
        }
      }

      # Convert at most ONE long include (--requirement/--constraint) per line.
      if (match(line, /(^|[[:space:]])--(requirement|constraint)[[:space:]]+([^[:space:]]+)/, m2)) {
        inc2 = m2[3]; abs2 = abs_path(inc2)
        if (abs2 != inc2) {
          pre2 = substr(line, 1, RSTART-1)
          post2 = substr(line, RSTART+RLENGTH)
          line = pre2 sprintf("%s--%s %s", m2[1], m2[2], abs2) post2
        }
      }

      # Comments
      if (line ~ /^[[:space:]]*#/) { print line; next }

      # If psycopg[binary] is already present, remember (Python 3.13 wheels).
      if (line ~ /\bpsycopg\[binary\]\b/) { have_v3=1; print line; next }

      # Drop any psycopg2 / psycopg2-binary lines (with pins/markers).
      if (line ~ /^[[:space:]]*psycopg2(-binary)?([[:space:]]*[=<>!~]{1,2}[^[:space:]]+)?([[:space:]]*;.*)?[[:space:]]*$/) { next }

      print line
    }
    END { if (!have_v3) print "psycopg[binary]>=3.1.19" }
  ' "$in" > "$out"
}


# Return 0 if dev file includes the runtime file (via -r), else 1
dev_includes_runtime() {
  local dev="$1" run="$2"
  [[ -z "$dev" || -z "$run" ]] && return 1
  local base="$(basename "$run")"
  grep -Eiq "(^|\s)-r\s+.*${base}" "$dev" && return 0 || true
  grep -Eiq "(^|\s)--requirement\s+.*${base}" "$dev" && return 0 || true
  grep -Eiq "(^|\s)-r\s+.*${run}" "$dev" && return 0 || true
  grep -Eiq "(^|\s)--requirement\s+.*${run}" "$dev" && return 0 || true
  return 1
}

pip_install_file() {
  local label="$1" req="$2"
  if [[ -z "$req" ]]; then
    warn "No ${label} requirements file found. Skipping."
    return 0
  fi

  local start end rc verbosity tmp tmp_win
  start=$(date +%s)

  # Verbosity: 0 none, 1 -v, 2 -vv
  verbosity=""
  if [[ "${DEPS_VERBOSE:-1}" -ge 2 ]]; then
    verbosity="-vv"
  elif [[ "${DEPS_VERBOSE:-1}" -ge 1 ]]; then
    verbosity="-v"
  fi

  compute_dep_logs  # sets PIP_LOG and TEE_LOG

  if is_windows; then
    # Normalize requirements file for Windows AND convert its path for Windows Python
    tmp="$(mktemp /tmp/req.win.XXXXXX.txt)"
    prepare_win_requirements "$req" "$tmp" || { err "Prep Windows req for ${label} failed."; exit 1; }
    tmp_win="$tmp"
    command -v cygpath >/dev/null 2>&1 && tmp_win="$(cygpath -w "$tmp")"

    step "Installing ${label} deps from (Windows-adjusted) ${tmp_win}"
    info "pip log → ${PIP_LOG}"
    info "stream  → ${TEE_LOG}"
    "$PY" -m pip install ${verbosity} --no-input --disable-pip-version-check --progress-bar off \
      --log "$PIP_LOG" -r "$tmp_win" 2>&1 | tee -a "$TEE_LOG"
  else
    step "Installing ${label} deps from ${req}"
    info "pip log → ${PIP_LOG}"
    info "stream  → ${TEE_LOG}"
    "$PY" -m pip install ${verbosity} --no-input --disable-pip-version-check --progress-bar off \
      --log "$PIP_LOG" -r "$req" 2>&1 | tee -a "$TEE_LOG"
  fi

  rc=${PIPESTATUS[0]}  # exit code of pip (first cmd in the pipe)
  end=$(date +%s)
  if (( rc != 0 )); then
    err "pip install for ${label} failed (rc=${rc}). Last 50 lines:"
    ( tail -n 50 "$TEE_LOG" 2>/dev/null || tail -n 50 "$PIP_LOG" 2>/dev/null || true )
    exit "$rc"
  fi
  info "${label} deps installed in $((end-start))s"
}



### ----------------------------
### Pre-flight
### ----------------------------
# Load .env if present
if [ -f .env ]; then
  step "Loading .env"
  # shellcheck disable=SC2046
  export $(grep -v '^\s*#' .env | sed -E 's/\s*#.*$//' | xargs -0 -I {} sh -c 'echo {}' 2>/dev/null || true)
fi

# Export critical env (don’t overwrite if .env already set)
export POLICY_DIR POLICY_FILE JWT_SECRET DB_HOST DB_PORT DB_NAME DB_USER DB_PASS
export SKIP_OCR_LIVE  # make sure pytest sees it

# Decide DB strategy now
DB_MODE="sqlite"
if [[ "$DEV_MODE" = "1" && "$SKIP_LOCAL_DB" != "1" && $(has_docker && echo ok || echo no) = "ok" ]]; then
  DB_MODE="docker-pg"
fi
if [[ "$DB_MODE" = "docker-pg" ]]; then
  export USE_SQLITE=0
else
  export USE_SQLITE=1
fi

step "Checking required tools"
need_cmd curl
PY="$(detect_python)"
ok "Using $($PY -V 2>&1)"

# Print effective env summary (safe subset)
info "Env summary:
  APP_MODULE=$APP_MODULE
  POLICY_DIR=$POLICY_DIR
  POLICY_FILE=$POLICY_FILE
  DB_MODE=$DB_MODE  (USE_SQLITE=${USE_SQLITE})
  DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_NAME=$DB_NAME DB_USER=$DB_USER
  JWT_SECRET=${JWT_SECRET:0:4}********
  DEV_MODE=$DEV_MODE LIVE_LOGS=$LIVE_LOGS SKIP_LOCAL_DB=$SKIP_LOCAL_DB SKIP_OCR_LIVE=$SKIP_OCR_LIVE
  DEPS_LOG_FILE=$DEPS_LOG_FILE
  LOG_FILE=$LOG_FILE"

### ----------------------------
### Venv
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

step "Upgrading pip tooling"
compute_dep_logs
"$PY" -m pip install -U pip setuptools wheel --disable-pip-version-check \
  --log "$PIP_LOG" 2>&1 | tee -a "$TEE_LOG"
ok "Upgraded packaging tools (logs → $TEE_LOG)"

step "Ensuring SQLAlchemy runtime"
if ! "$PY" - <<'PY' >/dev/null 2>&1
import importlib
importlib.import_module("sqlalchemy")
PY
then
  info "Installing SQLAlchemy (not found)"
  "$PY" -m pip install "SQLAlchemy>=2.0,<3.0" >/dev/null || "$PY" -m pip install "SQLAlchemy>=2.0,<3.0"
else
  info "SQLAlchemy already present"
fi

# Pin so future installs keep it
if ! grep -iq '^sqlalchemy' backend/requirements.txt; then
  info "Pinning SQLAlchemy==2.0.35 in backend/requirements.txt"
  printf '\nSQLAlchemy==2.0.35\n' >> backend/requirements.txt
fi
ok "SQLAlchemy ready"




# ----------------------------
# Dependencies
# ----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REQ_FILE_RESOLVED="$(resolve_file "${REQUIREMENTS_FILE}" "backend")"
DEV_REQ_FILE_RESOLVED="$(resolve_file "${DEV_REQUIREMENTS_FILE}" "backend")"

if [[ "$SKIP_DEV_DEPS" = "1" ]]; then
  step "SKIP_DEV_DEPS=1 set — installing runtime only."
  pip_install_file "runtime" "$REQ_FILE_RESOLVED"
else
  if [[ -n "$DEV_REQ_FILE_RESOLVED" && -n "$REQ_FILE_RESOLVED" ]] && dev_includes_runtime "$DEV_REQ_FILE_RESOLVED" "$REQ_FILE_RESOLVED"; then
    step "Dev requirements include runtime (-r). Installing dev only."
    pip_install_file "dev" "$DEV_REQ_FILE_RESOLVED"
  else
    pip_install_file "runtime" "$REQ_FILE_RESOLVED"
    pip_install_file "dev"     "$DEV_REQ_FILE_RESOLVED"
  fi
fi
ok "Dependencies installed"

# Ensure backend pkg
if [ -d "backend" ] && [ ! -f "backend/__init__.py" ]; then
  step "Creating backend/__init__.py"
  printf "" > backend/__init__.py
  ok "backend/__init__.py created"
fi

### ----------------------------
### Start local Postgres (DEV) via Docker when chosen
### ----------------------------
if [[ "$DB_MODE" = "docker-pg" ]]; then
  need_cmd docker
  start_local_pg
  wait_for_pg_container
else
  info "Using SQLite (USE_SQLITE=1) — not starting Dockerized Postgres."
fi

### ----------------------------
### Tests
### ----------------------------
step "Running test suite"
# Ensure pytest exists even when dev reqs are slim
python -m pip show pytest >/dev/null 2>&1 || python -m pip install pytest >/dev/null

# Pass through optional pytest opts
if ! "$PY" -m pytest -q ${PYTEST_ADDOPTS}; then
  err "Tests failed. Aborting."
  exit 1
fi
ok "All tests passed"

### ----------------------------
### Optional DB migration
### ----------------------------
if [ -f "alembic.ini" ] && command -v alembic >/dev/null 2>&1; then
  step "Running Alembic migrations"
  alembic upgrade head || warn "Alembic failed (continuing)"
fi

### ----------------------------
### Start server
### ----------------------------
step "Starting FastAPI server (${APP_MODULE}) on ${HOST}:${PORT}"
: > "$LOG_FILE"

UVICORN_ARGS=( "${APP_MODULE}" --host "${HOST}" --port "${PORT}" --log-level info )
if [ "${DEV_MODE}" = "1" ]; then
  UVICORN_ARGS+=( --reload )
fi

"$PY" -m uvicorn "${UVICORN_ARGS[@]}" >>"$LOG_FILE" 2>&1 &
UV_PID=$!
ok "Uvicorn PID ${UV_PID}"
info "Logs: ${LOG_FILE}"

if [ "$LIVE_LOGS" = "1" ]; then
  info "LIVE_LOGS=1 → streaming logs (Ctrl+C stops tail; server keeps running)"
  tail -n +1 -f "$LOG_FILE" &
  TAIL_PID=$!
fi

### ----------------------------
### Health check
### ----------------------------
API_BASE="http://${HOST}:${PORT}"
HEALTH_URLS=("${API_BASE}/health" "${API_BASE}/docs" "${API_BASE}/")

step "Health check (timeout: ${HEALTH_TIMEOUT_SECONDS}s)"
HC_OK=1
for url in "${HEALTH_URLS[@]}"; do
  info "Checking ${url}"
  if wait_for_http "${url}" "${HEALTH_TIMEOUT_SECONDS}"; then
    ok "Healthy: ${url}"
    HC_OK=0
    break
  fi
done

if [ $HC_OK -ne 0 ]; then
  err "Health check failed. See ${LOG_FILE}"
  exit 1
fi

echo
echo -e "${GREEN}${BOLD}🎉 API UP!${RESET}"
echo -e "   ${BOLD}Base:${RESET} ${API_BASE}"
echo -e "   ${BOLD}Docs:${RESET} ${API_BASE}/docs"
echo -e "   ${BOLD}PID :${RESET} ${UV_PID}"
echo -e "   ${BOLD}Stop:${RESET} kill ${UV_PID}"
echo
