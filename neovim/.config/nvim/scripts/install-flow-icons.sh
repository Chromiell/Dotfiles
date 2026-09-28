#!/usr/bin/env bash
# Downloads the Flow Icons VS Code theme extension (open-vsx) and extracts the
# extension root so real-icons.nvim can load it as nvim icon pack "flow".
# See https://open-vsx.org/extension/thang-nm/flow-icons
#
# Always resolves the latest version from the Open VSX API. If the pack is
# already installed and up to date, it exits early. An outdated install is
# replaced in place. Requires network access only for the API call + download.
# Run "sh ~/.config/nvim/scripts/install-flow-icons.sh" manually or via the
# lazy.nvim build step, or let the icons.lua startup check invoke it.
# POSIX sh compatible (no bashisms) so it runs under any /bin/sh, incl. dash.
set -eu

dest="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/real-icons/packs/flow-icons"
endpoint="https://open-vsx.org/api/thang-nm/flow-icons/latest"

installed_version=""
if [ -f "$dest/package.json" ]; then
    installed_version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dest/package.json" | head -n1)
fi

# Resolve the latest published version (jq when available, grep fallback).
# curl may fail or time out; tolerate it so the offline branch below decides.
latest_json=""
latest_json="$(curl -fsSL --max-time 15 "$endpoint")" || latest_json=""
if [ -z "$latest_json" ]; then
    if [ -n "$installed_version" ]; then
        echo "Could not reach Open VSX; keeping installed Flow Icons ${installed_version}"
        exit 0
    fi
    echo "Could not reach Open VSX and no Flow Icons install exists." >&2
    exit 1
fi
version=$(printf '%s' "$latest_json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
if [ -z "$version" ]; then
    echo "Could not resolve the latest Flow Icons version." >&2
    exit 1
fi

if [ "$installed_version" = "$version" ]; then
    echo "Flow Icons ${version} already installed at $dest"
    exit 0
fi

if [ -n "$installed_version" ]; then
    echo "Upgrading Flow Icons ${installed_version} -> ${version}..."
else
    echo "Downloading Flow Icons ${version}..."
fi

url="https://open-vsx.org/api/thang-nm/flow-icons/${version}/file/thang-nm.flow-icons-${version}.vsix"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL --max-time 60 "$url" -o "$tmp/flow-icons.vsix"

echo "Extracting into $dest..."
mkdir -p "$tmp/ext" "$dest"
if command -v bsdtar >/dev/null 2>&1; then
    bsdtar -xf "$tmp/flow-icons.vsix" -C "$tmp/ext"
elif command -v unzip >/dev/null 2>&1; then
    unzip -q "$tmp/flow-icons.vsix" -d "$tmp/ext"
elif command -v 7z >/dev/null 2>&1; then
    7z x "$tmp/flow-icons.vsix" -o"$tmp/ext" >/dev/null
else
    python3 - "$tmp/flow-icons.vsix" "$tmp/ext" <<'PY'
import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])
PY
fi

# Wipe the old pack so files removed upstream do not linger.
rm -rf "$dest"
cp -r "$tmp/ext/extension/." "$dest/"

# Recolor the DEFAULT directory icon (folder_gray -> folder_blue). Flow Icons
# ships generic folders in gray; real-icons picks the default folder icon
# straight from the manifest "folder"/"folderExpanded"/"rootFolder*" keys and
# offers no config hook for them (path rules would also override named
# folders like src/test). Swap only those top-level defaults to the blue
# variant where the icon definition exists; named/special folders keep their
# own icons. Idempotent: already-replaced manifests are left untouched.
python3 - "$dest" <<'PY'
import json, os, sys

DEFAULT_KEYS = ("folder", "folderExpanded", "rootFolder", "rootFolderExpanded")
changed = 0
for dirpath, _, files in os.walk(sys.argv[1]):
    for name in files:
        if not name.endswith(".json"):
            continue
        path = os.path.join(dirpath, name)
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError):
            continue
        if not isinstance(data, dict) or not isinstance(data.get("iconDefinitions"), dict):
            continue
        definitions = data["iconDefinitions"]
        modified = False
        for key in DEFAULT_KEYS:
            value = data.get(key)
            if isinstance(value, str) and "_gray" in value:
                replacement = value.replace("_gray", "_blue")
                if replacement in definitions:
                    data[key] = replacement
                    modified = True
        if modified:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(data, fh)
            changed += 1
print(f"Default folder icon recolored to blue in {changed} manifest(s)")
PY

echo "Flow Icons ${version} installed at $dest"
