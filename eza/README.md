# Eza Configuration

Configuration and theme styling for [eza](https://github.com/eza-community/eza), a modern, colorized replacement for `ls`.

---

## 📦 Required Packages

To install `eza` on Debian-based systems:

```bash
sudo apt update
sudo apt install eza
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`fonts`](../fonts) | Assets / Icons | File and directory iconography (`--icons`) relies on **Adwaita Mono Nerd Font** from the fonts module. |
| [`zsh`](../zsh) | Complementary Shell | Provides custom Zsh aliases and functions (`l`, `la`, `ll`, `llt`, `lll`, `ld`, etc.) integrating with `eza`. |


---

## 📂 Structure

- `.config/eza/theme.yml`: Custom color and icon styling themes for file types, permissions, sizes, and timestamps.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow eza
```
