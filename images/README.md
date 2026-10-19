# Wallpapers & Images

Collection of wallpapers, backgrounds, and shared desktop imagery.

---

## 📑 Index

- [Dotfiles Module Dependencies & Related Modules](#-dotfiles-module-dependencies--related-modules)
- [Structure](#-structure)
- [Usage with GNU Stow](#-usage-with-gnu-stow)

---

## 🧩 Dotfiles Module Dependencies & Related Modules

| Module | Relationship | Description |
| :--- | :--- | :--- |
| [`niri`](../niri) | Desktop Environment | Provides wallpaper assets used by desktop environments and wallpaper switchers (e.g. DMS `Mod+Y` in Niri). |

---

## 📂 Structure

- `Pictures/Shared/Dark_Forest.png`: Default high-resolution dark-themed landscape wallpaper.

---

## 🚀 Usage with GNU Stow

Symlink images to your `~/Pictures` directory:

```bash
cd ~/.dotfiles
stow images
```
