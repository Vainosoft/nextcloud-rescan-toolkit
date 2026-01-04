#!/bin/sh
set -eu

# scripts/nextcloud_scan.sh
# Nextcloud rescan helper for script_server UI.
# Supports:
# - mode=all
# - mode=path user=<USER> folder=<FOLDER>
# - mode=path scan_path=<USER>/files/<FOLDER>

# Load optional local config (NOT committed)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/config.sh" ] && . "$SCRIPT_DIR/config.sh"

# Defaults (safe placeholders)
C="${NC_CONTAINER:-nextcloud}"
OCC="${NC_OCC:-/var/www/html/occ}"
RUN_UID="${NC_RUN_UID:-33}"
LOG_DIR_DEFAULT="$SCRIPT_DIR/../scan_logs"
LOG_DIR="${NC_LOG_DIR:-$LOG_DIR_DEFAULT}"
DOCKER_BIN="$(command -v docker || echo /usr/bin/docker)"

mkdir -p "$LOG_DIR"

# For debugging how script_server passes arguments
echo "Raw args: [$*]"

MODE="all"        # all | path
SCAN_PATH=""      # explicit relative path like USER/files/Photos
USER_NAME=""      # dropdown: USER
FOLDER=""         # text: Photos or Documents/2025

# Parse args from script_server (often "key value" pairs) + accept key=value
while [ $# -gt 0 ]; do
  case "$1" in
    all|path)
      MODE="$1"; shift ;;

    mode|--mode)
      shift; MODE="${1:-all}"; [ $# -gt 0 ] && shift || true ;;

    scan_path|path|--path|--scan_path)
      shift; SCAN_PATH="${1:-}"; [ $# -gt 0 ] && shift || true ;;

    user|username)
      shift; USER_NAME="${1:-}"; [ $# -gt 0 ] && shift || true ;;

    folder|subpath)
      shift; FOLDER="${1:-}"; [ $# -gt 0 ] && shift || true ;;

    mode=*|--mode=*)
      MODE="${1#*=}"; shift ;;

    scan_path=*|path=*|--path=*|--scan_path=*)
      SCAN_PATH="${1#*=}"; shift ;;

    user=*|username=*)
      USER_NAME="${1#*=}"; shift ;;

    folder=*|subpath=*)
      FOLDER="${1#*=}"; shift ;;

    *)
      # ignore unknown tokens safely
      shift ;;
  esac
done

# Normalize
MODE="$(printf "%s" "$MODE" | tr -d ' \t\r\n')"
SCAN_PATH="$(printf "%s" "$SCAN_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
USER_NAME="$(printf "%s" "$USER_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
FOLDER="$(printf "%s" "$FOLDER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
[ -z "$MODE" ] && MODE="all"

# Fallback if mode is weird
if [ "$MODE" != "all" ] && [ "$MODE" != "path" ]; then
  MODE="all"
fi

# Build scan path from user+folder if scan_path not provided
if [ "$MODE" = "path" ] && [ -z "$SCAN_PATH" ] && [ -n "$USER_NAME" ]; then
  SCAN_PATH="${USER_NAME}/files"
  [ -n "$FOLDER" ] && SCAN_PATH="${SCAN_PATH}/${FOLDER}"
fi

# Validate scan path if needed
if [ "$MODE" = "path" ]; then
  if [ -z "$SCAN_PATH" ]; then
    echo "ERROR: Mode=path requires either scan_path OR user (and optional folder)"
    echo "Examples:"
    echo "  mode=path scan_path=USER/files/Photos"
    echo "  mode=path user=USER folder=Photos"
    echo "  mode=path user=USER   (scans entire user files root)"
    exit 2
  fi
  case "$SCAN_PATH" in
    /*|*..*)
      echo "ERROR: invalid SCAN_PATH (must be relative, without '..')"
      exit 2 ;;
  esac
fi

TS="$(date +%Y%m%d_%H%M%S)"
LOG="$LOG_DIR/nextcloud_scan_${MODE}_${TS}.log"

echo "== Nextcloud scan =="
echo "Container: $C"
echo "Mode: $MODE"
[ "$MODE" = "path" ] && echo "Scan path: $SCAN_PATH"
echo "Log: $LOG"
echo ""

# Stream output live + write to log
FIFO="/tmp/ncscan_${TS}_$$.fifo"
mkfifo "$FIFO"

if [ "$MODE" = "all" ]; then
  "$DOCKER_BIN" exec -u "$RUN_UID" "$C" php "$OCC" files:scan --all >"$FIFO" 2>&1 &
else
  "$DOCKER_BIN" exec -u "$RUN_UID" "$C" php "$OCC" files:scan --path="$SCAN_PATH" >"$FIFO" 2>&1 &
fi

PID=$!
tee -a "$LOG" < "$FIFO"
wait "$PID"
RC=$?

rm -f "$FIFO"

echo "" | tee -a "$LOG"
echo "Exit code: $RC" | tee -a "$LOG"
echo "Done." | tee -a "$LOG"
exit "$RC"
