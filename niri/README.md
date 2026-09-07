# Niri Configuration

Configuration files for [Niri](https://github.com/niri-wm/niri), a scrollable-tiling Wayland compositor.

---

## 📦 Required Packages

To use Niri and associated Wayland desktop tools on Debian-based systems refer to the [DankMaterialShell](https://danklinux.com/) project.

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`kitty`](../kitty) | Default Terminal | Launched via the `Mod+T` keybinding in `dms/binds.kdl`. |
| [`scripts`](../scripts) | Script Execution | The OCR screen text grabber shortcut (`Mod+Shift+E` in `dms/binds.kdl`) executes `~/Documents/Scripts/grab_text.sh`. |


---

## 📂 Structure

- `.config/niri/config.kdl`: Main entry point configuration file in KDL format.
- `.config/niri/dms/`: Modular KDL sub-configurations:
  - `binds.kdl`: Keybindings for workspace switching, window navigation, and launching applications.
  - `layout.kdl`: Window gaps, column widths, border styles, and layout settings.
  - `colors.kdl`: Color palettes and focus border color styling.
  - `windowrules.kdl`: Rules for specific application windows (floating, default sizes, opacity).
  - `outputs.kdl`: Display resolution, scale, and multi-monitor output configuration.
  - `input.kdl`: Keyboard layouts, touchpad sensitivity, and mouse acceleration settings.
  - `cursor.kdl`: Wayland cursor size and theme settings.
  - `wpblur.kdl`: Wallpaper and background blur rules.
  - `alttab.kdl`: Alt-Tab task switcher rules.
  - `niri-smart-maximize.sh`: Helper script for intelligent window toggle and maximization.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow niri
```
