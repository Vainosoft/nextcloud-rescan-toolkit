#!/bin/sh
set -eu

# scripts/nextcloud_cleanup_scan_logs_keep_last.sh
# Delete older scan logs, keeping only the newest N logs (default 20).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/config.sh" ] && . "$SCRIPT_DIR/config.sh"

LOG_DIR_DEFAULT="$SCRIPT_DIR/../scan_logs"
LOG_DIR="${NC_LOG_DIR:-$LOG_DIR_DEFAULT}"
KEEP_DEFAULT=20
KEEP="$KEEP_DEFAULT"

# Accept: keep 20 / keep=20 / 20
for a in "$@"; do
  v="$a"
  case "$v" in
    *=*) v="${v#*=}" ;;
  esac
  case "$v" in
    ''|*[!0-9]*) : ;;
    *) KEEP="$v" ;;
  esac
done

echo "Log directory: $LOG_DIR"
echo "Keeping last: $KEEP logs"
echo "----------------------------------------"

ls "$LOG_DIR"/nextcloud_scan_*.log >/dev/null 2>&1 || { echo "No logs found. Nothing to do."; exit 0; }

TOTAL="$(ls -1 "$LOG_DIR"/nextcloud_scan_*.log | wc -l | tr -d ' ')"
echo "Total logs found: $TOTAL"

if [ "$TOTAL" -le "$KEEP" ]; then
  echo "Nothing to delete (total <= keep)."
  exit 0
fi

TO_DELETE="$(ls -1t "$LOG_DIR"/nextcloud_scan_*.log | tail -n +"$((KEEP+1))")"
DEL_COUNT="$(printf "%s\n" "$TO_DELETE" | wc -l | tr -d ' ')"

echo "Will delete: $DEL_COUNT log(s) (oldest ones)"
echo "----------------------------------------"
printf "%s\n" "$TO_DELETE" | sed 's|^|DELETE: |'

printf "%s\n" "$TO_DELETE" | xargs -r rm -f

echo "----------------------------------------"
echo "Done. Remaining logs: $(ls -1 "$LOG_DIR"/nextcloud_scan_*.log | wc -l | tr -d ' ')"
