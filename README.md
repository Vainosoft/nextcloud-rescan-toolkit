# Nextcloud Rescan Toolkit (Asustor + Docker + script_server)

This toolkit helps Nextcloud **discover files copied directly on the NAS** by running `occ files:scan` via a web UI (script_server), without needing SSH for day-to-day use.

> ✅ Privacy note: This repository is intentionally **anonymized**. Replace placeholders (container name, host paths, usernames) using your local `scripts/config.sh` (not committed).

---

## What problem this solves

If you copy files directly into the Nextcloud **data directory** on the host (NAS) rather than uploading via the Nextcloud web UI / WebDAV / Desktop client, Nextcloud won't automatically update its file cache. You must run:

- `occ files:scan --all` (all users / all files), or
- `occ files:scan --path="<user>/files/<folder>"` (scoped scan)

This toolkit provides web buttons to run these scans, plus logging and log cleanup.

---

## Repository structure

```
nextcloud-rescan-toolkit/
  README.md
  .gitignore
  scripts/
    config.sample.sh
    nextcloud_scan.sh
    nextcloud_show_last_log.sh
    nextcloud_list_scan_logs.sh
    nextcloud_cleanup_scan_logs_keep_last.sh
```

**Not committed:**
- `scripts/config.sh` (your real environment values)
- scan logs (ignored by `.gitignore`)

---

## Prerequisites

- Nextcloud running in Docker on an Asustor NAS (ADM)
- You have a way to run scripts on the NAS:
  - **script_server** (recommended) for a web UI, or
  - SSH for initial setup only

---

## Configure (required)

### 1) Create `scripts/config.sh` (local only, not committed)

Copy the sample:

- From: `scripts/config.sample.sh`
- To: `scripts/config.sh`

Fill in your real values:

- `NC_CONTAINER` — Docker container name running Nextcloud
- `NC_OCC` — path to `occ` inside the container (often `/var/www/html/occ`)
- `NC_RUN_UID` — UID to run `occ` as (commonly `33` for `www-data`)
- `NC_LOG_DIR` — host directory where logs should be written

Example (placeholder-only):

```sh
NC_CONTAINER="nextcloud"
NC_OCC="/var/www/html/occ"
NC_RUN_UID="33"
NC_LOG_DIR="/path/to/scan_logs"
```

---

## Scripts overview

### `scripts/nextcloud_scan.sh`
Main entrypoint.

Supported modes:
- Scan everything:
  - `mode=all`
- Scan user or subfolder:
  - `mode=path user=<USER> folder=<FOLDER>`
  - If `folder` is empty, scans `<USER>/files`
- Manual path override:
  - `mode=path scan_path=<USER>/files/<FOLDER>`

It writes a log file for each run:
- `nextcloud_scan_all_YYYYMMDD_HHMMSS.log`
- `nextcloud_scan_path_YYYYMMDD_HHMMSS.log`

### `scripts/nextcloud_show_last_log.sh`
Shows the tail of the most recent scan log.

- Accepts an optional numeric argument (lines), default 200.

### `scripts/nextcloud_list_scan_logs.sh`
Lists the latest scan logs (newest first). Default shows 30.

### `scripts/nextcloud_cleanup_scan_logs_keep_last.sh`
Deletes old logs and keeps only the newest N logs (default 20).

---

## script_server setup (recommended)

### Install
Install **script_server** from ADM App Central.

### Admin UI
Open the admin page:

- `http://<NAS-IP>:<SCRIPT_SERVER_PORT>/admin.html`

Create a group named `Nextcloud` (optional).

### Add web buttons

#### Button 1: "Nextcloud: Scan files" (flexible)
- Script: `scripts/nextcloud_scan.sh`
- Parameters:
  - `mode` (list): `all`, `path`
  - `user` (list): your Nextcloud usernames (must match folder names under `<DATA_DIR>/<user>/`)
  - `folder` (text): e.g. `Photos` or `Documents/2025` (optional)
  - `scan_path` (text): advanced override, e.g. `<USER>/files/<FOLDER>`

Usage:
- All users: `mode=all`
- Single user root: `mode=path user=USER folder=(empty)` → scans `USER/files`
- Subfolder: `mode=path user=USER folder=Photos` → scans `USER/files/Photos`

#### Button 2: "Nextcloud: Scan ALL"
- Script: `scripts/nextcloud_scan.sh`
- Default `mode=all`

#### Button 3: "Nextcloud: Show last scan log"
- Script: `scripts/nextcloud_show_last_log.sh`
- Parameter: `lines` (number, default 200)

#### Button 4: "Nextcloud: List scan logs"
- Script: `scripts/nextcloud_list_scan_logs.sh`
- Parameter: `count` (number, default 30)

#### Button 5: "Nextcloud: Cleanup scan logs (keep last 20)"
- Script: `scripts/nextcloud_cleanup_scan_logs_keep_last.sh`
- Parameter: `keep` (number, default 20)

---

## Logs

Scan logs are written to:

- `NC_LOG_DIR` (from `scripts/config.sh`)

Recommended naming:
- `nextcloud_scan_all_YYYYMMDD_HHMMSS.log`
- `nextcloud_scan_path_YYYYMMDD_HHMMSS.log`

---

## Troubleshooting

### 1) `occ` complains about config ownership
If `occ` says it must be executed by the owner of `config/config.php`, align ownership and permissions to the web user (commonly `www-data`, UID 33), **in a way that matches your environment**.

### 2) Data directory issues
Nextcloud expects a marker file `.ncdata` in the root of the data directory.

### 3) Permissions
If files were copied with incorrect ownership/permissions, Nextcloud may not read them. Fix ownership to match your container's expected user.

---

## Security notes

- Don’t expose script_server publicly without authentication and network restrictions.
- Treat these scripts as privileged operations: they call `docker exec`.
- Never commit your `scripts/config.sh`.

---

## Quick start (NAS)

### A) Copy scripts to the NAS
1. Copy the `scripts/` folder from this repo to your NAS (any location you prefer).
2. Make scripts executable on the NAS:
   ```sh
   chmod +x /path/to/scripts/*.sh


