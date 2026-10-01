# Documents

Personal technical documentation, reference notes, and how-to guides stowed under `~/Documents/Guides`.

---

## 🧩 Dotfiles Module Dependencies & Related Modules

| Module | Relationship | Description |
| :--- | :--- | :--- |
| [`scripts`](../scripts) | Shared Directory | Both modules stow into `~/Documents`; `scripts` provides the `Documents/Scripts` and `Documents/ScriptsData` trees. |

---

## 📂 Structure

- `Documents/Guides/NVIDIA_ZINK.md`: Guide for forcing a Proton/Steam **OpenGL** game to render through **Zink** on the NVIDIA dGPU of an Optimus laptop. Covers the root cause (`__NV_PRIME_RENDER_OFFLOAD` being a no-op for Vulkan device ordering inside the Steam Linux Runtime container), the working Steam launch options using Mesa device selection (`DRI_PRIME` / `MESA_VK_DEVICE_SELECT`), verification commands, and fallbacks.
- `Documents/Guides/FLOW_ICONS_RECOLOR.md`: Guide for recoloring the **default (generic) directory icon** of the Flow Icons theme from gray to the built-in blue variant (`folder_gray` → `folder_blue`) in VS Code / VSCodium / Cursor / Windsurf (PowerShell patch, re-run after extension updates). The Neovim side is automated by `neovim`'s `install-flow-icons.sh`.

---

## 🚀 Usage with GNU Stow

> ⚠️ **Create `~/Documents` first.** It is shared with the `scripts` module and
> may contain your own files, so it must already exist as a real directory.
> Otherwise Stow replaces it with a single symlink into the repository.

```bash
mkdir -p ~/Documents
cd ~/.dotfiles
stow documents
```

`~/Documents/Guides` then becomes a symlink to this module, while `~/Documents`
itself stays a real directory where `scripts` and your own files can coexist.
