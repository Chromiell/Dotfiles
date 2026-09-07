# Fastfetch Configuration

Configuration presets for [Fastfetch](https://github.com/fastfetch-cli/fastfetch), a fast and highly customizable system information tool written in C.

---

## 📦 Required Packages

To install Fastfetch on Debian-based systems:

```bash
sudo apt update
sudo apt install fastfetch
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`fonts`](../fonts) | Assets / Icons | System info module glyphs (OS, CPU, GPU, memory, etc.) in `fastfetch.jsonc` require **Adwaita Mono Nerd Font**. |
| [`zsh`](../zsh) | Complementary Shell | Automatically invokes Fastfetch upon new interactive shell sessions and provides an alias for it. |


---

## 📂 Structure

- `.config/fastfetch/fastfetch.jsonc`: JSONC configuration defining the displayed system information modules (OS, kernel, uptime, packages, shell, WM, terminal, CPU, GPU, memory, etc.) and visual layout.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow fastfetch
```
