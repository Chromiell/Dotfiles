# Kitty Configuration

Configuration files for [Kitty](https://sw.kovidgoyal.net/kitty/), a fast, feature-rich, GPU-based terminal emulator.

---

## 📦 Required Packages

To install and use Kitty on Debian-based systems:

```bash
sudo apt update
sudo apt install kitty
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`scripts`](../scripts) | Assets / Typography | `kitty.conf` is configured to use the **Adwaita Mono Nerd Font Mono** installed by `install-adwaita-nerd-font` (`font_family family="AdwaitaMono Nerd Font Mono"`). |


---

## 📂 Structure

- `.config/kitty/kitty.conf`: Primary Kitty configuration including fonts, window layouts, tabs, keyboard shortcuts, and theme colors.
- `.config/kitty/kitty-startup.session`: Startup session configuration defining initial tabs and window splits.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow kitty
```
