#!/usr/bin/env bash
# Downloads the Flow Icons VS Code theme extension (open-vsx) and extracts the
# extension root so real-icons.nvim can load it as nvim icon pack "flow".
# See https://open-vsx.org/extension/thang-nm/flow-icons
set -euo pipefail

version="2.0.9"
url="https://open-vsx.org/api/thang-nm/flow-icons/${version}/file/thang-nm.flow-icons-${version}.vsix"
dest="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/real-icons/packs/flow-icons"

if [[ -f "$dest/package.json" ]]; then
    echo "Flow Icons already installed at $dest"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Flow Icons ${version}..."
curl -fsSL "$url" -o "$tmp/flow-icons.vsix"

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
cp -r "$tmp/ext/extension/." "$dest/"

echo "Flow Icons installed at $dest"
