# Zsh Configuration

A rich, responsive, and modern Zsh configuration optimized for Debian-based systems featuring **Znap** plugin management, the **Powerlevel10k** prompt theme, auto-suggestions, substring search, syntax highlighting, and custom aliases.

---

## 📦 1. Required Packages

### Required Core Packages
To use this Zsh configuration (including the Znap plugin manager):

```bash
sudo apt update
sudo apt install zsh git
```

### Recommended CLI Tools & Enhancements
For the complete terminal experience with all aliases, fast fetching, directory jumping, and enhanced previews:

```bash
sudo apt install eza fzf bat fastfetch rsync micro rar gzip tar unzip 7zip bzip2 fd-find ripgrep pv vim zoxide
```

---

## 🧩 Dotfiles Module Dependencies

This module integrates with and depends on several other modules in this repository:

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`fastfetch`](../fastfetch) | Runtime / Alias | Displayed on shell startup and aliased to use `~/.config/fastfetch/fastfetch.jsonc`. |
| [`eza`](../eza) | Aliases / Functions | Used for colorized file and directory listing aliases (`l`, `la`, `ll`, `llt`, `lll`, `ld`, etc.). |
| [`fzf`](../fzf) | Keybindings / Scripts | Powers fuzzy searching and the `ff` file preview alias (`~/.config/fzf/fzf-preview.sh`). |
| [`tmux`](../tmux) | Functions / Aliases | Helper functions (`t`, `taa`, `tbg`, `tsp`, `tlast`, `tnl`, `tp`) and shortcuts manage tmux sessions. |
| [`fonts`](../fonts) | Assets / Rendering | Powerlevel10k (`.p10k.zsh`) and CLI icons require **Adwaita Mono Nerd Font** for glyph rendering. |


---

## 🔗 2. Deploy Configuration with GNU Stow

From your dotfiles repository directory (assumed to be `~/.dotfiles`), stow the `zsh` package:

```bash
cd ~/.dotfiles
stow zsh
```

This creates symbolic links in your home directory:
- `~/.zshrc` $\rightarrow$ `~/.dotfiles/zsh/.zshrc`
- `~/.zshenv` $\rightarrow$ `~/.dotfiles/zsh/.zshenv`
- `~/.zprofile` $\rightarrow$ `~/.dotfiles/zsh/.zprofile`
- `~/.config/zsh-config/.p10k.zsh` $\rightarrow$ `~/.dotfiles/zsh/.config/zsh-config/.p10k.zsh`

---

## 🐚 3. Change Default Shell to Zsh

### Check Available Shells
Verify that Zsh is installed and listed in `/etc/shells`:

```bash
cat /etc/shells
```

You should see `/bin/zsh` or `/usr/bin/zsh` in the output.

### Set Zsh as Default Shell
Change your user's default login shell:

```bash
chsh -s $(which zsh)
```

> [!NOTE]
> Log out and log back in (or restart your terminal session) for the default shell change to take effect.

---

## ✨ 4. Features & Included Plugins

- **Znap Plugin Manager:** Automatically clones and manages lightweight Zsh plugins upon first launch without manual setup.
- **Powerlevel10k Prompt:** Ultra-fast, highly informative prompt with instant prompt loading and custom theme settings (`.p10k.zsh`).
- **Autocompletion & Autosuggestions:** Fast Fish-like suggestions (`zsh-autosuggestions`) and interactive menu completion (`zsh-autocomplete`).
- **Syntax Highlighting:** Real-time command syntax highlighting (`fast-syntax-highlighting`).
- **History Substring Search:** Interactive substring search through command history using arrow keys.
- **Productivity Enhancements:** Integrated `zoxide` directory jumping, `eza` aliases, `fastfetch` system info display, and extensive utility aliases.

---

## 🪟 Windows Terminal Configuration (Nerd Fonts)

To render icons and Powerlevel10k glyphs correctly in Windows Terminal:

1. Download **AdwaitaMono Nerd Font Mono** from [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases) (`AdwaitaMono.zip`), extract, and install the fonts on Windows.
2. In Windows Terminal Settings (JSON), set your profile font face to `AdwaitaMono Nerd Font Mono`.

Example profile configuration:

```json
{
    "profiles": {
        "defaults": {
            "colorScheme": "Custom Scheme",
            "font": {
                "face": "AdwaitaMono Nerd Font Mono",
                "size": 11
            },
            "intenseTextStyle": "bold",
            "opacity": 90
        }
    }
}
```
