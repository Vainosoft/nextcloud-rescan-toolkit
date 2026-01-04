#!/bin/sh
set -eu

# scripts/nextcloud_list_scan_logs.sh
# List latest Nextcloud scan logs (newest first) with timestamp and size.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/config.sh" ] && . "$SCRIPT_DIR/config.sh"

LOG_DIR_DEFAULT="$SCRIPT_DIR/../scan_logs"
LOG_DIR="${NC_LOG_DIR:-$LOG_DIR_DEFAULT}"
N_DEFAULT=30
N="$N_DEFAULT"

# Accept: count 20 / count=20 / 20
for a in "$@"; do
  v="$a"
  case "$v" in
    *=*) v="${v#*=}" ;;
  esac
  case "$v" in
    ''|*[!0-9]*) : ;;
    *) N="$v" ;;
  esac
done

echo "Log directory: $LOG_DIR"
echo "Showing last $N logs (newest first)"
echo "----------------------------------------"

ls "$LOG_DIR"/nextcloud_scan_*.log >/dev/null 2>&1 || { echo "No logs found."; exit 0; }

i=0
for f in $(ls -1t "$LOG_DIR"/nextcloud_scan_*.log | head -n "$N"); do
  i=$((i+1))
  ts="$(stat -c '%y' "$f" 2>/dev/null | cut -d'.' -f1)"
  sz="$(stat -c '%s' "$f" 2>/dev/null)"
  base="$(basename "$f")"
  printf "%2s) %s | %s bytes | %s\n" "$i" "$ts" "$sz" "$base"
done
