# Mouse Cursor Configuration

Default mouse cursor theme configuration for X11 and Wayland desktop environments.

---

## 📦 Required Packages

This directory contains static desktop theme pointer settings and requires no additional packages beyond a standard graphical desktop environment (X11 / Wayland).

---

## 🧩 Dotfiles Module Dependencies & Related Modules

| Module | Relationship | Description |
| :--- | :--- | :--- |
| [`niri`](../niri) | Desktop Environment | Sets the default XDG fallback cursor theme for Wayland and X11 compositor sessions. |


---

## 📂 Structure

- `.icons/default/index.theme`: Standard XDG cursor configuration setting the default cursor theme inheritance.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow mouseCursorDefault
```
