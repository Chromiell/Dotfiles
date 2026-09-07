# 🗺️ Tmux Configuration

A clean, modern Tmux setup featuring the **Catppuccin Mocha** theme, transparent status bar padding, system resource monitoring, and intuitive, prefix-less navigation keybindings.

---

## 🚀 Features

- **Prefix-less Navigation:** Move, resize, and swap panes instantly using `Alt` and `Ctrl` modifiers without hitting the prefix key first.
- **Catppuccin Mocha Theme:** A beautiful, dark pastel color palette with custom rounded status tabs.
- **Double-Height Status Bar:** Positioned at the top with a blank padding line underneath for a cleaner look.
- **Rich Status Modules:** Displays user/host, CPU utilization, Memory usage, Session name, Uptime, and Battery level.
- **True Color Support:** Configured for RGB, underline styles, and strikethroughs (optimized for modern terminal emulators like Alacritty or Kitty).

---

## 📦 Required Packages

To install Tmux and the helper utilities used by the status bar scripts on Debian-based systems:

```bash
sudo apt update
sudo apt install tmux
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`fonts`](../fonts) | Assets / Rendering | Custom Catppuccin status bar icons and rounded separators require **Adwaita Mono Nerd Font**. |
| [`zsh`](../zsh) | Complementary Shell | Provides custom Zsh functions (`t`, `taa`, `tbg`, `tsp`, `tlast`, `tnl`, `tp`) and shortcuts for managing tmux sessions. |


---

## 🛠️ Installation

This configuration is designed to be managed with **GNU Stow** inside a `~/.dotfiles` directory.

### 1. Install the configuration with Stow

Run the following command to use `GNU stow` to take care of the configuration:

```bash
cd ~/.dotfiles
stow tmux
```

### 2. Initialize Plugins

Once stowed, launch a new Tmux session and fetch/initialize the bundled plugins:

- Tmux should initialize automatically but, if it doesn't, you can press Prefix + I (default prefix is typically Ctrl+b unless overridden) to trigger TPM and load Catppuccin cleanly.

## ⌨️ Complete Keybindings Reference

Every major navigation, structural layout change, or operational shortcut has been mapped to direct key sequences.

### 🪟 Pane Management

| Shortcut              | Configuration Mapping   | Action                                                                  |
| :-------------------- | :---------------------- | :---------------------------------------------------------------------- |
| `Alt` + `←`           | `bind -n M-Left`        | Focus the pane to the **Left**                                 |
| `Alt` + `→`           | `bind -n M-Right`       | Focus the pane to the **Right**                                |
| `Alt` + `↑`           | `bind -n M-Up`          | Focus the pane **Above**                                       |
| `Alt` + `↓`           | `bind -n M-Down`        | Focus the pane **Below**                                       |
| `Alt` + `Shift` + `←` | `bind -n M-S-Left`      | Swap current pane with its **Left** neighbor and follow focus  |
| `Alt` + `Shift` + `→` | `bind -n M-S-Right`     | Swap current pane with its **Right** neighbor and follow focus |
| `Alt` + `Shift` + `↑` | `bind -n M-S-Up`        | Swap current pane with its **Upper** neighbor and follow focus |
| `Alt` + `Shift` + `↓` | `bind -n M-S-Down`      | Swap current pane with its **Lower** neighbor and follow focus |
| `Ctrl` + `Alt` + `←`  | `bind-key -n C-M-Left`  | Expand/Resize current pane **Leftward**                        |
| `Ctrl` + `Alt` + `→`  | `bind-key -n C-M-Right` | Expand/Resize current pane **Rightward**                       |
| `Ctrl` + `Alt` + `↑`  | `bind-key -n C-M-Up`    | Expand/Resize current pane **Upward**                          |
| `Ctrl` + `Alt` + `↓`  | `bind-key -n C-M-Down`  | Expand/Resize current pane **Downward**                        |
| `Alt` + `\|`           | `bind -n M-v`           | Split current window **Vertically** [side-by-side panes]       |
| `Alt` + `-`           | `bind -n M-h`           | Split current window **Horizontally** [top-and-bottom panes]   |

### 🗔 Window & Session Control

| Shortcut               | Configuration Mapping | Action                                                       |
| :--------------------- | :-------------------- | :----------------------------------------------------------- |
| `Ctrl` + `Shift` + `↑` | `bind -n C-S-Up`      | Jump to the **Previous** window                     |
| `Ctrl` + `Shift` + `↓` | `bind -n C-S-Down`    | Jump to the **Next** window                         |
| `Alt` + `1`            | `bind -n M-1`         | Jump directly to **Window 1**                       |
| `Alt` + `2`            | `bind -n M-2`         | Jump directly to **Window 2**                       |
| `Alt` + `3`            | `bind -n M-3`         | Jump directly to **Window 3**                       |
| `Alt` + `4`            | `bind -n M-4`         | Jump directly to **Window 4**                       |
| `Alt` + `d`            | `bind -n M-d`         | **Detach** instantly from the current session      |

---

## 📊 Status Line Dependencies

The right status string actively checks your operating system files or executes external local configurations. To view precise operational statistics, ensure the following local helper scripts are present and executable (`chmod +x`):

1. **CPU Usage:** `~/.config/tmux/cpu_usage.sh`
2. **Session Uptime:** `~/.config/tmux/uptime.sh` (which parses `#{session_created}`)
3. **Battery Statistics:** `~/.config/tmux/battery.sh` [configured to ingest Catppuccin theme color overrides]

> [!IMPORTANT]
> **Nerd Fonts Requirement:** To render custom status tabs, glyphs, and iconography properly (such as ``, ``, ``, ``, ``, `󰔟`), ensure that your host terminal emulator (e.g., Kitty, Alacritty, WezTerm) is actively configured to use a [Nerd Font](https://www.nerdfonts.com/).

---

## 🪝 Custom Autostart Hook

The config cleanly runs a passive hook sequence when creating a new workspace environment:

```tmux
if-shell "[ -f ~/.config/tmux/tmux-autostart.conf ]" {
    set-hook -g after-new-session "source-file ~/.config/tmux/tmux-autostart.conf"
}
```
