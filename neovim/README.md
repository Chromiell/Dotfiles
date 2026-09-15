# Neovim Setup Guide
This guide assumes you are using Debian as your base distribution. If you are using a different distribution, the package manager commands may differ.

## 1. Install Distrobox
Distrobox allows you to create and manage containerized environments. To install Distrobox, run the following command:

```bash
sudo apt install distrobox
```

## 2. Create a Distrobox Container
You can create a Distrobox container using the following command. We use Arch Linux Toolbox because it ships directly with the latest version of Neovim.

```bash
distrobox create -n arch -i quay.io/toolbx/arch-toolbox:latest
```

## 3. Enter the Distrobox Container
To enter the Distrobox container, use the following command:

```bash
distrobox enter arch
```

## 4. Install Paru

Paru is an AUR helper that simplifies the process of installing packages from the Arch User Repository (AUR). To install Paru, run the following commands inside the Distrobox container:

```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

## 5. Install Neovim and Dependencies
Once you are inside the Distrobox container, you can install Neovim using the package manager. For Arch Linux, use the following command:

```bash
paru -S neovim tree-sitter-cli curl lazygit wl-clipboard yazi ffmpeg 7zip jq poppler fd ripgrep fzf eza zoxide resvg imagemagick micro nodejs
```

> [!NOTE]
> `vim` is an **optional dependency** if you wish to use the standalone `.vimrc` configuration locally or test it outside the container without Neovim (`sudo apt install vim` on Debian/Ubuntu).

> [!TIP]
> To have PHP Intelephense  working, you will also need to install the `php` package and enable the iconv extension. You can do this by running the following command:

```bash
paru -S php composer
micro /etc/php/php.ini
```

Then, find the line that says `;extension=iconv` and remove the semicolon to enable the extension. Save the file and exit.

> [!TIP]
> To have spelling highlighting for English and Italian languages you need to manually install CSpell with NPM, you can install this package by exiting from the Distrobox container and installing [nvm](https://github.com/nvm-sh/nvm) in your base system, install the latest LTS version of Node and install the following package:

```bash
npm install -g cspell @cspell/dict-it-it @vlabo/cspell-lsp
```

Everything else should be taken care by Mason automatically.

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`php-cs-fixer`](../php-cs-fixer) | Formatter Config | Neovim's PHP formatter (`lua/plugins/php-cs-fixer.lua`) explicitly uses `~/.config/php-cs-fixer/.php-cs-fixer.php`. |
| [`composer`](../composer) | Package Manager | Global Composer configuration provides `friendsofphp/php-cs-fixer` used for formatting. |
| [`fonts`](../fonts) | Assets / Icons | File tree icons, Lualine statusline, and Snacks UI symbols require **Adwaita Mono Nerd Font**. |

---

## 6. Install LazyVim & Dotfiles
To deploy the configurations, run GNU Stow from the dotfiles directory:

```bash
cd ~/.dotfiles && stow neovim
```

> [!NOTE]
> Running `stow neovim` creates symbolic links for both the Neovim configuration (`~/.config/nvim`) and the standalone Vim configuration (`~/.vimrc`).

Once installed you can start Neovim by running:

```bash
nvim .
```

This will pull all necessary packages and set up LazyVim for you. You can customize your Neovim configuration by editing the files in the `~/.config/nvim` directory.

## 7. Exporting the nvim, yazi and lazygit binary

To use the Neovim, Yazi and Lazygit binaries outside of the Distrobox container, you can create symbolic links to the binaries in a directory that is included in your system's PATH. By default Distrobox exports binaries to `~/.local/bin`. Run the following commands:

```bash
distrobox-export --bin /bin/nvim
distrobox-export --bin /bin/yazi
distrobox-export --bin /bin/lazygit
```

---

## 8. Portable Standalone Vim Configuration (`.vimrc`)

This module includes a standalone [`.vimrc`](./.vimrc) file located in the module root. It is designed to be exported to remote servers, minimal container environments, or machines where Neovim cannot be installed, while providing an editing experience that closely resembles this local LazyVim setup.

### 🚀 Remote Deployment

To quickly copy the `.vimrc` configuration to any remote machine via SSH:

```bash
scp ~/.dotfiles/neovim/.vimrc user@remote-server:~/.vimrc
```

### ✨ Features & Included Utilities

The `.vimrc` is written in pure Vimscript with **zero plugin dependencies**. Vim 8.2+ is recommended because some enhanced features use popup and sign APIs; the core editing settings remain portable. Optional integrations use tools such as Git, `rg`, `file`, `date`, `sudo`, and Wayland clipboard utilities when available.

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
- **Search and quickfix**: `<leader>fg` or `<leader>\` searches the project with `rg --vimgrep` or native `vimgrep`; `<leader>ff` searches normally and `<leader>fh` temporarily includes hidden files. Quickfix entries can be deleted with `dd` or Visual `d`, and `[q`/`]q` navigate the list.
- **Buffer and window navigation**: `H`/`L`, `[b`/`]b`, `<leader>b[`/`<leader>b]`, `<leader>bb`, and `<leader>bd` manage buffers; `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move between windows; `<leader>wd` closes the current window.
- **Line movement**: `<A-j>`/`<A-k>` and `<M-j>`/`<M-k>` move lines in Normal, Visual, and Insert modes with boundary checks. Terminal, Kitty, Windows Terminal, and tmux keycode compatibility mappings are included.
- **Git and diff helpers**: `<leader>bc` compares two open buffers; `<leader>gd` opens a Git index diff; `<leader>gb` opens a 35-column blame sidebar; `<leader>gH` shows file history; `[h`/`]h` navigate Git hunks; `<leader>ghp` previews a hunk; and `<leader>ghr` resets the current hunk.
- **Git signs and file helpers**: Modified lines receive add/change/delete signs, symlinks are followed on read, file MIME type is cached for the statusline, and system commands run through a stderr-suppressing wrapper.
- **Netrw explorer**: `<leader>e` toggles a banner-free tree at the current file’s directory and `<leader>fe` opens Netrw directly. Inside Netrw, `a`, `r`, and `d` create, rename, and delete entries.
- **Completion and spelling**: Insert-mode arrow keys navigate the completion menu, `<Tab>` confirms suggestions, and completion can trigger after matching words. `<leader>uo` toggles spelling with English dictionary; `[s` and `]s` navigate spelling errors.
- **Automatic integrations**: Autocommands refresh Git status and signs, restore the last cursor position, apply filetype-specific indentation/comment settings, configure Quickfix and Netrw buffers, sync yanks through `wl-copy`, and keep the completion and whitespace helpers updated.
