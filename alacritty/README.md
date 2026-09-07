# Alacritty Configuration

Configuration files for [Alacritty](https://github.com/alacritty/alacritty), a fast, cross-platform, GPU-accelerated terminal emulator.

---

## 📦 Required Packages

To install and use Alacritty on Debian-based systems:

```bash
sudo apt update
sudo apt install alacritty
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`fonts`](../fonts) | Assets / Typography | Recommended to render Nerd Font icons and glyphs across CLI tools, prompt themes (P10k), and Tmux. |


---

## 📂 Structure

- `.config/alacritty/alacritty.toml`: Main configuration file for modern Alacritty versions, setting window padding, opacity, font families, and color imports.
- `.config/alacritty/alacritty.yml`: Legacy YAML configuration format fallback.
- `.config/alacritty/dank-theme.toml`: Custom theme palette definitions.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow alacritty
```
