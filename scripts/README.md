# Scripts Repository Documentation

This repository contains operational, deployment, backup, and utility scripts used for server administration, web application deployment, database backup/sync, system tweaks, and desktop productivity.

---

## 📦 Required Packages

The scripts utilize various utilities depending on the tasks you run. To install all common script dependencies on Debian-based systems:

```bash
sudo apt update
sudo apt install rsync curl expect msmtp certbot cifs-utils mariadb-client \
    flameshot imagemagick tesseract-ocr tesseract-ocr-eng tesseract-ocr-ita \
    wl-clipboard libnotify-bin x11-xserver-utils
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`niri`](../niri) | Consumer / Keybinding | `grab_text.sh` is bound to the `Mod+Shift+E` shortcut in `niri` for desktop OCR capture. |

---

## 📁 Directory Structure & Data Organization

To maintain security and separation of concerns, executable scripts, sensitive data files, and system utilities are organized across designated locations:

- **Scripts Directory:** `Documents/Scripts/` (or `~/Documents/Scripts/`)
  - Contains general executable operational and administrative shell scripts (`.sh`).
- **Data & Credentials Directory:** `Documents/ScriptsData/` (or `~/Documents/ScriptsData/`)
  - Contains configuration files, sensitive credentials, passwords, and email settings used by the scripts.
- **User Bin Directory:** `.local/bin/` (or `~/.local/bin/`)
  - Reserved for user-level system commands and driver/hardware configuration utilities (e.g., `toggle-nvidia-pm`).

### Sensitive Data & Configuration Files (`Documents/ScriptsData/`)

All sensitive environment variables, passwords, network addresses, and private configurations are isolated in `Documents/ScriptsData/` and ignored by Git.

| File Name | Description / Used By |
| :--- | :--- |
| `config.env` | Central configuration file defining sensitive variables (server hosts, IP addresses, database users, database names, dumped table lists, network shares). Ignored by Git. |
| `config.env.example` | Template file documenting all available configuration variables with sanitized placeholders. Tracked in Git. |

---

## 🛠️ Script Catalog

### 1. SSL & HAProxy Management

#### `certbotAddDomain.sh`
- **Location:** `Documents/Scripts/certbotAddDomain.sh`
- **Description:** Automates Let's Encrypt SSL certificate issuance via Certbot, constructs HAProxy-compatible PEM bundles, configures automated post-renewal hooks, and syncs certificate files to a secondary HAProxy node.
- **Data Dependencies:** Reads `REMOTE_HAPROXY_HOST` from `Documents/ScriptsData/config.env`.
- **Key Operations:**
  1. Invokes Certbot in standalone mode (`http-01` challenge on port `8888`) to issue a domain certificate.
  2. Combines `fullchain.pem` and `privkey.pem` into a single `.pem` file at `/etc/haproxy/ssl/<domain>.pem`.
  3. Reloads the local `haproxy` systemd service.
  4. Generates an executable post-renewal hook script under `/etc/letsencrypt/renewal-hooks/post/haproxy-<domain>.sh`.
  5. Uses `rsync` to synchronize `/etc/haproxy/ssl/` with the secondary HAProxy node (`REMOTE_HAPROXY_HOST`).
- **Usage:**
  ```bash
  ./certbotAddDomain.sh <domain>
  ```

#### `certbotDeleteDomain.sh`
- **Location:** `Documents/Scripts/certbotDeleteDomain.sh`
- **Description:** Safely de-provisions and cleans up all Let's Encrypt SSL certificates, renewal hooks, and HAProxy PEM files for a specified domain across both local and remote nodes.
- **Data Dependencies:** Reads `REMOTE_HAPROXY_HOST` from `Documents/ScriptsData/config.env`.
- **Key Operations:**
  1. Prompts a warning and brief pause before executing destructive deletions.
  2. Deletes local renewal config (`/etc/letsencrypt/renewal/<domain>.conf`).
  3. Deletes post-renewal hook script (`/etc/letsencrypt/renewal-hooks/post/haproxy-<domain>.sh`).
  4. Removes live and archive certificate directories (`/etc/letsencrypt/live/<domain>` and `/etc/letsencrypt/archive/<domain>`).
  5. Removes local HAProxy PEM (`/etc/haproxy/ssl/<domain>.pem`).
  6. Executes an SSH command to delete the corresponding remote PEM file on `REMOTE_HAPROXY_HOST`.
- **Usage:**
  ```bash
  ./certbotDeleteDomain.sh <domain>
  ```

---

### 2. Database Backup, Migration & Sync

#### `dumpMantisDB.sh`
- **Location:** `Documents/Scripts/dumpMantisDB.sh`
- **Description:** Creates a compressed backup of the local Mantis bug tracker database directly onto a CIFS/SMB network backup share while keeping a rolling retention history.
- **Data Dependencies:**
  - Reads share URL, credentials path, database user, and database name from `Documents/ScriptsData/config.env`.
  - Reads the local DB password from `MANTIS_LOCAL_DB_PASSWORD` in `Documents/ScriptsData/config.env`.
- **Key Operations:**
  1. Reads the database password from `config.env` or the environment.
  2. Mounts the CIFS network share (`MANTIS_CIFS_SHARE`) to the target mount directory using credentials (`MANTIS_CIFS_CREDENTIALS`).
  3. Scans existing backups on the share matching `database-YYYYMMDD.sql.gz` and prunes older entries, maintaining only the 2 most recent backups.
  4. Executes `mysqldump` with `--single-transaction` on the configured database (`MANTIS_DB_NAME`), compresses output with `gzip`, and writes to `$TARGET_DIR/database-YYYYMMDD.sql.gz`.
  5. Automatically unmounts the network share and removes the mount folder on exit via `trap`.

#### `nightlyProdDump.sh`
- **Location:** `Documents/Scripts/nightlyProdDump.sh`
- **Description:** Fetches selected database tables from a remote production MariaDB database over SSH, compresses the dump locally, imports it into a local MariaDB instance, and executes post-import database modifications.
- **Data Dependencies:**
  - Reads connection details (remote SSH host/user, remote DB user/name, local DB user/name, table list, dump directory) from `Documents/ScriptsData/config.env`.
  - Reads remote and local DB passwords from `PROD_DUMP_REMOTE_DB_PASSWORD` and `PROD_DUMP_LOCAL_DB_PASSWORD` in `Documents/ScriptsData/config.env`.
  - Invokes post-import script at `Documents/Scripts/postImportDBAlter.sh` (or `PROD_DUMP_POST_SCRIPT`).
- **Key Operations:**
  1. Maintains a rolling retention of the 2 most recent dump files in the configured dump directory (`PROD_DUMP_DIR`).
  2. Connects via SSH to the remote host (`PROD_DUMP_REMOTE_SSH_USER@PROD_DUMP_REMOTE_SSH_HOST`) and runs `mariadb-dump` for the tables specified in `PROD_DUMP_TABLES` on database `PROD_DUMP_REMOTE_DB_NAME`.
  3. Saves compressed output to `$PROD_DUMP_DIR/dump-YYYYMMDD.sql.gz`.
  4. Decompresses and imports the dump into the local database (`PROD_DUMP_LOCAL_DB_NAME`).
  5. Executes `postImportDBAlter.sh` to apply post-import schema/data alterations.

#### `moveDBDump.sh`
- **Location:** `Documents/Scripts/moveDBDump.sh`
- **Description:** Synchronizes today's local production dump file to a remote CIFS/SMB network backup share and maintains a 2-backup retention policy on the share.
- **Data Dependencies:** Reads CIFS share and credential paths from `Documents/ScriptsData/config.env`.
- **Key Operations:**
  1. Verifies local dump file presence in `SOURCE_DIR`.
  2. Mounts the CIFS network share (`MOVE_DUMP_CIFS_SHARE`) to the target mount directory using credentials (`MOVE_DUMP_CIFS_CREDENTIALS`).
  3. Cleans up older dumps on the share matching `dump-YYYYMMDD.sql.gz`, keeping only the 2 newest files.
  4. Copies today's dump file while preserving file modes and timestamps.
  5. Safely unmounts and cleans up the mount point on script exit.

#### `postImportDBAlter.sh`
- **Location:** `Documents/Scripts/postImportDBAlter.sh`
- **Description:** Iterates over PHP database migration or setup scripts inside the configured directory and triggers them via silent HTTP requests.
- **Data Dependencies:** Reads `POST_IMPORT_BASE_DIR` and `POST_IMPORT_URL_BASE` from `Documents/ScriptsData/config.env`.
- **Key Operations:**
  1. Scans `$POST_IMPORT_BASE_DIR/*.php`.
  2. Skips `index.php`.
  3. Executes `curl` silently against `${POST_IMPORT_URL_BASE}/<filename>` with a 1-second timeout per script.

#### `sftpGrab.sh`
- **Location:** `Documents/Scripts/sftpGrab.sh`
- **Description:** Automated `expect` script for interactive SFTP downloading of database dumps from a development host.
- **Dependencies:** `expect` package.
- **Data Dependencies:** Reads `SFTP_HOST`, `SFTP_USER`, `SFTP_PASSWORD`, `SFTP_REMOTE_FILE`, and `SFTP_LOCAL_DIR` from `Documents/ScriptsData/config.env` or environment variables.
- **Key Operations:**
  1. Sets a default timeout of 30 seconds.
  2. Connects to `SFTP_USER@SFTP_HOST` via SFTP.
  3. Passes password authentication automatically via `expect`/`send`.
  4. Downloads `SFTP_REMOTE_FILE` to local directory `SFTP_LOCAL_DIR`.

---

### 3. Web Application Deployment & Maintenance

#### `gitpull.sh`
- **Location:** `Documents/Scripts/gitpull.sh`
- **Description:** Continuous deployment script that pulls the latest changes from Git and executes build pipelines across multiple applications hosted under `DEPLOY_ROOT`.
- **Data Dependencies:** Reads `DEPLOY_ROOT` and target directory names from `Documents/ScriptsData/config.env`.
- **Target Applications & Actions:**
  - Target 1 (`DEPLOY_TARGET_1`): `git pull`, `npm run prod`, `npm run prod-elearning`, `npm run prod-b`, Tailwind CSS minification.
  - Target 2 (`DEPLOY_TARGET_2`): `git pull`, `npm run prod-file`.
  - Target 3 (`DEPLOY_TARGET_3`): `git pull`.
  - Target 4 (`DEPLOY_TARGET_4`): `git pull`.
  - Target 5 (`DEPLOY_TARGET_5`): `git pull`, `npm run build`.
- **Permissions:** Sets group ownership recursively to `www-data` for all updated project folders.

#### `gitpullPostScript.sh`
- **Location:** `Documents/Scripts/gitpullPostScript.sh`
- **Description:** Restores proper directory and file ownership for the backend application storage directory.
- **Data Dependencies:** Reads `DEPLOY_STORAGE_DIR` from `Documents/ScriptsData/config.env`.
- **Target Directory:** Configured via `DEPLOY_STORAGE_DIR` in `config.env`.
- **Action:** `chown --silent -R www-data:www-data`

---

### 4. System Administration, Hardware & Desktop Utilities

#### `toggle-nvidia-pm`
- **Location:** `.local/bin/toggle-nvidia-pm`
- **Description:** System management script that toggles NVIDIA GPU Dynamic Power Management in modprobe configuration, rebuilds initramfs, and handles system reboot prompts.
- **Key Operations:**
  1. Checks for root privileges and auto-elevates using `sudo` if necessary.
  2. Searches `/etc/modprobe.d/nvidia.conf` for `options nvidia NVreg_DynamicPowerManagement=0x02`.
  3. Comments or uncomments the parameter using `sed` to switch status between ENABLED and DISABLED (appends line if missing).
  4. Runs `update-initramfs -u` to apply driver module parameter changes.
  5. Prompts the user to immediately reboot the system.

#### `toggle_paperwm.sh`
- **Location:** `Documents/Scripts/toggle_paperwm.sh`
- **Description:** Toggles state of the PaperWM GNOME Shell Extension (`paperwm@paperwm.github.com`) between ACTIVE and INACTIVE.
- **Key Operations:**
  1. Queries status via `gnome-extensions info paperwm@paperwm.github.com`.
  2. Disables extension if currently active; enables extension if inactive.
  3. Displays status notifications via `notify-send`.

#### `swap.sh`
- **Location:** `Documents/Scripts/swap.sh`
- **Description:** Simulates virtual key press sequences using `ydotool` to automate UI interactions.
- **Dependencies:** `ydotool` daemon.
- **Key Operations:** Issues automated key-down/key-up events with precise sleep intervals.

#### `checkUpdates.sh`
- **Location:** `Documents/Scripts/checkUpdates.sh`
- **Description:** Scheduled maintenance utility that checks APT for available software package upgrades and dispatches an email notification if updates are pending.
- **Data Dependencies:**
  - Email sender, recipient, subject, body, and SMTP password: `Documents/ScriptsData/config.env`

#### `enable-freesync.sh`
- **Location:** `Documents/Scripts/enable-freesync.sh`
- **Description:** Startup utility to enable tearing prevention on X11 display sessions.
- **Key Operations:**
  1. Checks if `XDG_SESSION_TYPE` equals `x11` (exits immediately if running Wayland).
  2. Waits 15 seconds to allow the desktop compositor to initialize.
  3. Runs `xrandr --output eDP --set "TearFree" on`.

#### `grab_text.sh`
- **Location:** `Documents/Scripts/grab_text.sh`
- **Description:** Screen capture OCR tool that allows selecting any region on the screen, extracting text using Tesseract (English + Italian), and copying the text to the clipboard.
- **Dependencies:** `flameshot`, `imagemagick` (`mogrify`), `tesseract-ocr` (`tesseract-ocr-eng`, `tesseract-ocr-ita`), `wl-clipboard` (`wl-copy`), `libnotify-bin` (`notify-send`).

---

## 🔒 Security & Administrative Notes

1. **Credentials & Secrets Isolation:** All sensitive credentials, database passwords, network share locations, server hosts, and private configurations are stored strictly inside `Documents/ScriptsData/config.env`. This file is ignored by Git (`.gitignore`) and must never be committed to version control.
2. **Configuration Setup:** When deploying on a new machine, copy `Documents/ScriptsData/config.env.example` to `Documents/ScriptsData/config.env` and configure appropriate environment values.
3. **Path Distinctions:** Standard user scripts reside under `Documents/Scripts/`, whereas binary/hardware toggles intended for terminal invocation (e.g., `toggle-nvidia-pm`) reside in `.local/bin/`.
4. **File Permissions:**
   - Executable scripts in `Documents/Scripts/` and `.local/bin/` require execution rights (`chmod +x`).
   - Secret files in `Documents/ScriptsData/` (e.g., `config.env`) should have restricted file permissions (`chmod 600` or `chmod 400`).
