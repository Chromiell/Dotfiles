# Documents

Personal technical documentation, reference notes, and how-to guides stored under `~/Documents`.

---

## 🧩 Dotfiles Module Dependencies & Related Modules

| Module | Relationship | Description |
| :--- | :--- | :--- |
| [`scripts`](../scripts) | Shared Directory | Both modules stow into `~/Documents`; `scripts` provides the `Documents/Scripts` and `Documents/ScriptsData` trees. |

---

## 📂 Structure

- `Documents/NVIDIA_ZINK.md`: Guide for forcing a Proton/Steam **OpenGL** game to render through **Zink** on the NVIDIA dGPU of an Optimus laptop. Covers the root cause (`__NV_PRIME_RENDER_OFFLOAD` being a no-op for Vulkan device ordering inside the Steam Linux Runtime container), the working Steam launch options using Mesa device selection (`DRI_PRIME` / `MESA_VK_DEVICE_SELECT`), verification commands, and fallbacks.

---

## 🚀 Usage with GNU Stow

Symlink the documents into your `~/Documents` directory:

```bash
cd ~/.dotfiles
stow documents
```
