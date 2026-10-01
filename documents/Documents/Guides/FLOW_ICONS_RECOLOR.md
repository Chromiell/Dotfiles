# Flow Icons — Recolor Default Folders to Blue

[Flow Icons](https://marketplace.visualstudio.com/items?itemName=thang-nm.flow-icons) ships its **generic** (default) directory icon in gray (`folder_gray`). Special folders such as `src`, `test`, `docs` have their own semantic icons and are unaffected.

This guide recolors the *default* folder icon to the pack's built-in blue variant (`folder_blue`, `#3b82f6`) in **both** of the places where the theme is consumed:

1. **VS Code (and VSCodium / Cursor / Windsurf)** — patch the installed extension manifests (the patch is done manually because it is a client-side, non-Linux location).
2. **Neovim** — handled automatically by this dotfiles repository (`neovim/.config/nvim/scripts/install-flow-icons.sh` post-processes the manifests on every install/update; no manual action needed).

> [!NOTE]
> Like patching a theme, VS Code **rewrites these files whenever the extension updates**, so re-run the patch after upgrading Flow Icons.
> VS Code only re-reads icon-theme JSONs after a **Developer: Reload Window**.

---

## How the recolor works

Icon-theme manifests (`dim.json`, `deep.json`, `dawn.json`, `you.json`) carry four top-level default keys:

| Manifest key | Gray default | Blue replacement |
| :--- | :--- | :--- |
| `folder` | `folder_gray` | `folder_blue` |
| `folderExpanded` | `folder_gray_open` | `folder_blue_open` |
| `rootFolder` | `folder_root` | `folder_blue` |
| `rootFolderExpanded` | `folder_root_open` | `folder_blue_open` |

The root-folder keys use the `folder_root` definitions, not `folder_gray`; there is no `folder_root_blue`, so roots are pointed at the same `folder_blue` icons used for regular folders.

Only these four top-level defaults are swapped (when the replacement definition exists). `folderNames` / `folderNamesExpanded` entries — which give `src`, `test`, etc. their own colors — are left untouched; the same applies to extension/file associations.

---

## 1. VS Code / VSCodium / Cursor / Windsurf (Windows client)

Run in **PowerShell** on the machine where the editor is installed (Remote/WSL users: the extension and its icon themes live client-side, so patch there).

```powershell
# Point at the right extension root for your editor:
#   VS Code : .vscode\extensions    VSCodium : .vscodium\extensions
#   Cursor  : .cursor\extensions    Windsurf : .windsurf\extensions
$ext = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\thang-nm.flow-icons-*" -Directory | Select-Object -First 1
if (-not $ext) { Write-Error "Flow Icons extension not found"; exit 1 }

foreach ($f in (Get-ChildItem $ext.FullName -Recurse -Filter *.json)) {
    $c = Get-Content $f.FullName -Raw
    $new = $c `
        -replace '"folder"\s*:\s*"folder_gray"',              '"folder": "folder_blue"' `
        -replace '"folderExpanded"\s*:\s*"folder_gray_open"', '"folderExpanded": "folder_blue_open"' `
        -replace '"rootFolder"\s*:\s*"folder_root"',          '"rootFolder": "folder_blue"' `
        -replace '"rootFolderExpanded"\s*:\s*"folder_root_open"', '"rootFolderExpanded": "folder_blue_open"'
    if ($new -ne $c) { Set-Content $f.FullName $new -Encoding UTF8; Write-Host "patched $($f.Name)" }
}
```

Then reload the window: `Ctrl+Shift+P` → **Developer: Reload Window**.

---

## 2. VS Code / VSCodium / Cursor / Windsurf (native Linux)

Run in a terminal on the machine where the editor is installed. The command detects all four editor extension roots and patches whichever of them have Flow Icons installed:

```bash
python3 - <<'PY'
import glob, json, os

# Extension roots for VS Code, VSCodium, Cursor, Windsurf.
# NOTE: Python's glob has no brace expansion, so expand explicitly.
home = os.path.expanduser("~")
roots = []
for d in (".vscode", ".vscode-oss", ".vscodium", ".cursor", ".windsurf"):
    roots += glob.glob(os.path.join(home, d, "extensions", "thang-nm.flow-icons-*"))

# Manifest-level DEFAULT folder keys, same as the Windows patch.
KEYS = [
    ("folder", "folder_gray", "folder_blue"),
    ("folderExpanded", "folder_gray_open", "folder_blue_open"),
    ("rootFolder", "folder_root", "folder_blue"),
    ("rootFolderExpanded", "folder_root_open", "folder_blue_open"),
]

for ext in roots:
    for raw in glob.glob(os.path.join(ext, "*.json")):
        with open(raw, encoding="utf-8") as fh:
            data = json.load(fh)
        if not isinstance(data, dict) or not isinstance(data.get("iconDefinitions"), dict):
            continue
        defs, changed = data["iconDefinitions"], False
        for key, old, new in KEYS:
            if data.get(key) == old and new in defs:
                data[key] = new
                changed = True
        if changed:
            with open(raw, "w", encoding="utf-8") as fh:
                json.dump(data, fh)
            print("patched", raw)
PY
```

Then reload the window: `Ctrl+Shift+P` → **Developer: Reload Window**.

> [!NOTE]
> For an extension installed system-wide or as a Flatpak, adjust the root: Flatpak hosts extensions under `~/.var/app/com.visualstudio.code/config/Code/User/...` patterns may differ — easiest check is `code --list-extensions-dir`. The script only needs a directory containing the Flow Icons theme JSONs.

---

## 3. Neovim (already automated)

Nothing to do manually. `neovim/.config/nvim/scripts/install-flow-icons.sh` applies an equivalent Python post-process after every pack install/upgrade (see the `DEFAULT_KEYS` block in the script). Trigger a re-check anytime with:

```
:RealIcons packs
```
