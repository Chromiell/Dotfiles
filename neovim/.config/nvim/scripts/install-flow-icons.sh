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

echo "Flow Icons ${version} installed at $dest"
