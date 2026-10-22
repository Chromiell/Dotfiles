# Kitty Configuration

Configuration files for [Kitty](https://sw.kovidgoyal.net/kitty/), a fast, feature-rich, GPU-based terminal emulator.

---

## 📑 Index

- [Required Packages](#-required-packages)
- [Dotfiles Module Dependencies](#-dotfiles-module-dependencies)
- [Structure](#-structure)
- [Machine-Local Overrides](#-machine-local-overrides)
- [Usage with GNU Stow](#-usage-with-gnu-stow)

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
- `.config/kitty/kitty.local.conf`: Optional, **gitignored** machine-local overrides included at the end of `kitty.conf`.

---

## 🖥 Machine-Local Overrides

`kitty.conf` ends with an `include kitty.local.conf` directive so each machine can
override the tracked settings without editing version-controlled files. Relative
paths resolve against the config directory, a missing file is only logged (never
fatal), and options set later win over earlier ones.

```conf
# Create on the host that needs overrides, e.g. a different monitor DPI
font_size 13.3
background_opacity 0.95
```

Because `~/.config/kitty` is a single symlink into this module, the file physically
lives at `.config/kitty/kitty.local.conf` in the repository but is excluded via
`.gitignore` — the same pattern as the `dank-theme.conf` / `dank-tabs.conf` entries.
Use `globinclude kitty.d/*.conf` instead of the single `include` if several drop-in
files are wanted, or `globinclude kitty.d/${WSL_DISTRO_NAME}/*.conf` to load WSL-only
overrides (it silently matches nothing on non-WSL hosts).

Note that list-like options accumulate rather than replace: extra `map` lines add
bindings, and extra `font_family` lines become fallback fonts in order, so override
fonts with a single line in the local file.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow kitty
```
