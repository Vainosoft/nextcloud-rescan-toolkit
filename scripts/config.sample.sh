# Copy this file to: scripts/config.sh (NOT committed)
# Fill in your real values on the NAS/host where the scripts run.


# Docker container name for Nextcloud
NC_CONTAINER="nextcloud"


# Path to occ inside the container (common: /var/www/html/occ)
NC_OCC="/var/www/html/occ"


# UID to run occ as inside container (commonly 33 for www-data)
NC_RUN_UID="33"


# Host directory where scan logs should be written
# Example: "/path/to/nextcloud/scan_logs"
NC_LOG_DIR="/path/to/scan_logs"