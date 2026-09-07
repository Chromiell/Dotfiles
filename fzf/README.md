# FZF Configuration

Configuration and preview helper scripts for [fzf](https://github.com/junegunn/fzf), the interactive command-line fuzzy finder.

---

## 📦 Required Packages

To use `fzf` with full syntax-highlighted previews on Debian-based systems:

```bash
sudo apt update
sudo apt install fzf bat eza
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`kitty`](../kitty) | Terminal Integration | `fzf-preview.sh` utilizes `kitten icat` for in-terminal image previews when running inside Kitty. |
| [`eza`](../eza) | Preview Helper | Utilized for structured, icon-enhanced directory previews. |
| [`zsh`](../zsh) | Complementary Shell | Integrates interactive fuzzy completion bindings and the rich `ff` preview alias. |


---

## 📂 Structure

- `.config/fzf/fzf-preview.sh`: Rich preview generator script that dynamically previews text files (with syntax highlighting via `bat`), directories (via `eza`), images/media, and archives when navigating with `fzf`.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow fzf
```
