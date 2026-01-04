#!/bin/sh
set -eu

# scripts/nextcloud_show_last_log.sh
# Show tail of the most recent Nextcloud scan log.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/config.sh" ] && . "$SCRIPT_DIR/config.sh"

LOG_DIR_DEFAULT="$SCRIPT_DIR/../scan_logs"
LOG_DIR="${NC_LOG_DIR:-$LOG_DIR_DEFAULT}"
LINES="${1:-200}"

# Accept formats like: lines 200 / lines=200 / 200
for a in "$@"; do
  v="$a"
  case "$v" in
    *=*) v="${v#*=}" ;;
  esac
  case "$v" in
    ''|*[!0-9]*) : ;;
    *) LINES="$v" ;;
  esac
done

LAST_LOG="$(ls -t "$LOG_DIR"/nextcloud_scan_*.log 2>/dev/null | head -n 1 || true)"
if [ -z "$LAST_LOG" ]; then
  echo "No scan logs found in: $LOG_DIR"
  exit 1
fi

echo "Last log: $LAST_LOG"
echo "Showing last $LINES lines"
echo "----------------------------------------"
tail -n "$LINES" "$LAST_LOG"
