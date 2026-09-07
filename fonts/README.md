# Fonts

Custom fonts and glyph sets required for proper terminal icons, status bars, and UI glyph rendering.

---

## 📦 Required Packages

To manage and refresh font caches on Debian-based systems:

```bash
sudo apt update
sudo apt install fontconfig
```

---

## 🧩 Dotfiles Module Dependencies & Consumers

This module provides the core **Adwaita Mono Nerd Font** assets required across several other modules in this repository:

| Module | Usage / Integration |
| :--- | :--- |
| [`kitty`](../kitty) | Configured directly as the primary font family in `kitty.conf`. |
| [`alacritty`](../alacritty) | Used for terminal rendering, glyphs, and iconography. |
| [`zsh`](../zsh) | Required for Powerlevel10k prompt icons and terminal tools. |
| [`tmux`](../tmux) | Required for Catppuccin status bar icons, battery, and tab separators. |
| [`fastfetch`](../fastfetch) | Required for system info module icons and layout symbols. |
| [`eza`](../eza) | Required for file and directory icons (`--icons`). |
| [`neovim`](../neovim) | Required for file-tree icons, Lualine statusline, and Snacks UI symbols. |


---

## 📂 Structure

- `.local/share/fonts/`: Contains font files, including variations of **Adwaita Mono Nerd Font** (Regular, Bold, Italic, BoldItalic, Mono, and Propo variants).

---

## 🚀 Usage with GNU Stow

Symlink the fonts into your user font directory and refresh the font cache:

```bash
cd ~/.dotfiles
stow fonts
fc-cache -fv
```
