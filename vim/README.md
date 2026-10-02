# Vim Setup Guide

Portable standalone Vim configuration mirroring the local Neovim / LazyVim environment. It is designed to be exported to remote servers, minimal container environments, or machines where Neovim cannot be installed, while providing an editing experience that closely resembles the [Neovim module](../neovim) LazyVim setup.

---

## 🧩 Dotfiles Module Dependencies & Related Modules

| Module | Relationship | Description |
| :--- | :--- | :--- |
| [`neovim`](../neovim) | Related Module | The `.vimrc` intentionally mirrors the LazyVim environment of the `neovim` module (keybinds, TokyoNight Moon palette, statusline ...). |

---

## 📂 Structure

- `.vimrc`: Portable standalone Vim configuration written in pure Vimscript, located in the module root.

---

## 🚀 Usage with GNU Stow

Symlink the configuration to your home directory:

```bash
cd ~/.dotfiles
stow vim
```

This creates the symbolic link `~/.vimrc` → `~/.dotfiles/vim/.vimrc`.

### 🚀 Remote Deployment

To quickly copy the `.vimrc` configuration to any remote machine via SSH:

```bash
scp ~/.dotfiles/vim/.vimrc user@remote-server:~/.vimrc
```

---

## 📦 Required Packages

```bash
sudo apt install vim
```

Vim 8.2+ is recommended because some enhanced features use popup and sign APIs; the core editing settings remain portable. The `.vimrc` is written in pure Vimscript with **zero plugin dependencies**.

Optional integrations use the following tools when they are available: Git, `rg`, `file`, `date`, `sudo`, `fd`/`fdfind`, and the Wayland clipboard utilities `wl-clipboard` (`wl-copy` / `wl-paste`).

---

## ✨ Features & Included Utilities

- **Editor foundation**: 4-space indentation, UTF-8 and clipboard defaults, hidden buffers, persistent swap/undo/viminfo data in runtime storage, relative line numbers, cursorline, mouse support, wrapping, whitespace visualization, smart search, history, and histogram-based diffs.
- **TokyoNight Moon UI**: TrueColor theme with syntax, search, popup, quickfix, diff, Git-sign, statusline, and bufferline highlights. The configuration falls back to terminal colors when TrueColor is unavailable.
- **Dynamic statusline**: Shows the current mode, file name, modified/read-only state, file type, encoding and format, cursor position, Git branch, and a cached count of changed files. The statusline adapts its content to the available window width.
- **Top bufferline**: Displays listed buffers with active-buffer highlighting, modified indicators, optional pin markers, custom buffer ordering, and navigation/reordering commands.
- **Whitespace tools**: Highlights trailing whitespace and toggles that highlighting with `<leader>cT`; trims trailing whitespace from the current file or a Visual selection with `<leader>ct`.
- **Color conversion**: `<leader>co` and `:ToggleHexHsl` convert the color under the cursor between `#RRGGBB` and `hsl(H, S%, L%)`.
- **Date conversion**: `<leader>cx` converts a Visual selection between Unix timestamps and `YYYY-MM-DD HH:MM:SS` dates, using the system `date` command or a Python 3 fallback.
- **Project path utility**: `<leader>fP` detects a project root from `.git`, `package.json`, or `Makefile`, then copies the buffer’s relative path to the system and unnamed registers.
- **Formatting and editing**: `<leader>cf` indents a file or Visual selection; `<Tab>` and `<S-Tab>` preserve Visual mode while indenting; `gcc` and `gc` toggle comments; `gsa` surrounds a Visual selection; and `<leader>mi` starts the pure-Vim multi-cursor submode.
- **Save and file management**: `<C-s>` saves named and unnamed buffers, prompts for a filename when needed, and falls back to `sudo tee` for protected files. `<leader>fn` creates a new buffer, while `<leader>bp` pins the current buffer and `<leader>bP` closes unpinned buffers.
- **Marks and signs**: `m` interactively sets letter marks and displays them in the sign column; `<leader>md` removes marks from the current line; `<leader>mD` removes all local, global, and numbered marks.
- **Search and quickfix**: `<leader>fg` or `<leader>\` searches the project with `rg --vimgrep` or native `vimgrep`; `<leader>ff` searches normally using fuzzyfind with fzf if it's found in the system, otherwise it falls back to using find. Quickfix entries can be deleted with `dd` or Visual `d`, and `[q`/`]q` navigate the list.
- **Buffer and window navigation**: `H`/`L`, `[b`/`]b`, `<leader>b[`/`<leader>b]`, `<leader>bb`, and `<leader>bd` manage buffers; `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move between windows; `<leader>wd` closes the current window.
- **Line movement**: `<A-j>`/`<A-k>` and `<M-j>`/`<M-k>` move lines in Normal, Visual, and Insert modes with boundary checks. Terminal, Kitty, Windows Terminal, and tmux keycode compatibility mappings are included.
- **Git and diff helpers**: `<leader>bc` compares two open buffers; `<leader>gd` opens a Git index diff; `<leader>gb` opens a 35-column blame sidebar; `<leader>gH` shows file history; `[h`/`]h` navigate Git hunks; `<leader>ghp` previews a hunk; and `<leader>ghr` resets the current hunk.
- **Git signs and file helpers**: Modified lines receive add/change/delete signs, symlinks are followed on read, file MIME type is cached for the statusline, and system commands run through a stderr-suppressing wrapper.
- **Netrw explorer**: `<leader>e` toggles a banner-free tree at the current file’s directory and `<leader>fe` opens Netrw directly. Inside Netrw, `a`, `r`, and `d` create, rename, and delete entries.
- **Completion and spelling**: Insert-mode arrow keys navigate the completion menu, `<Tab>` confirms suggestions, and completion can trigger after matching words. `<leader>uo` toggles spelling with English dictionary; `[s` and `]s` navigate spelling errors.
- **Automatic integrations**: Autocommands refresh Git status and signs, restore the last cursor position, apply filetype-specific indentation/comment settings, configure Quickfix and Netrw buffers, sync yanks through `wl-copy`, and keep the completion and whitespace helpers updated.
