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
| [`tmux`](../tmux) | Terminal Pass-through | `set -g allow-passthrough on` in `~/.config/tmux/tmux.conf` is required so `real-icons.nvim` can render Kitty Graphics Protocol image icons while Neovim runs inside a tmux session. |

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

## 8. Real File Icons (real-icons.nvim)

File and folder icons are rendered as **real terminal images** through the Kitty Graphics Protocol using [real-icons.nvim](https://github.com/Mirsmog/real-icons.nvim), with the icon pack taken from the **Flow Icons** VS Code theme (variant *Flow Deep*).

- **Pack source:** the icons.lua build step runs `~/.config/nvim/scripts/install-flow-icons.sh`, which downloads the Flow Icons extension from Open VSX into `~/.local/share/nvim/real-icons/packs/flow-icons`. The script resolves the **latest published version** every run (early-exits when the installed pack matches, replaces an outdated pack in place).
- **Startup update:** after `UIEnter`, `icons.lua` queries the Open VSX API in a background `vim.system` job; when a newer release exists and the network is reachable, the installer runs automatically and Neovim notifies the user to restart. Everything stays silent on network failure, and the existing pack is never touched in that case.
- **Recoloring:** Flow Icons' default (generic) directory icon is gray; the installer post-processes each manifest's top-level `folder` / `folderExpanded` / `rootFolder*` defaults from the `folder_gray` to the `folder_blue` definition (blue-ish fill `#3b82f6`), so plain folders render blue while named special folders (`src`, `test`, …) keep their own icons. NET: this is wired into the installer so re-installs/upgrades re-apply it automatically.
- **Switching variants:** edit `theme` in `lua/plugins/icons.lua` (`flow-deep`, `flow-dim`, `flow-dawn`, `flow-you`) or pick another pack at runtime with `:RealIcons packs` (use `s` to save the default).
- **Icon size:** `size = { padding = 7 }` in `lua/plugins/icons.lua` adds a transparent margin inside the 64px PNG canvas, shrinking the visible glyph (~22% at 7) while the reserved 2×1 terminal-cell footprint stays the same. Increase `padding` for smaller icons, decrease for larger; `size.pixels` controls raster sharpness only, not displayed size. Changing `padding` regenerates the PNG cache on first render.
- **Terminal requirements:** image icons only render in **Ghostty** or **Kitty**. Inside tmux the tmux module's `allow-passthrough` option is required. WezTerm, Neovide, Windows Terminal, etc. automatically fall back to font icons (`mini.icons` / Nerd Font).
- **Input-buffer noise in tmux (`snacks.image`):** when a picker (e.g. `<leader><space>`) previews an image, `snacks.image` probes the terminal with `\e[>q` (XTVERSION). Its tmux workaround ([folke/snacks.nvim#2332](https://github.com/folke/snacks.nvim/issues/2332)) only runs when a `tmux` binary exists and `extended-keys` is exactly `on`. Inside the Distrobox container there is **no `tmux`**, so the workaround never runs and the probe reply (e.g. `kitty(0.48.2)`) leaks into the input buffer. `lua/plugins/snacks.lua` pre-seeds the terminal detection (kitty + tmux passthrough transform) whenever snacks' workaround is unusable, so no probe is sent; on the host (or if `tmux` is added to the container with `extended-keys on`) it is skipped and snacks handles it natively.
- **Dependencies:** `ImageMagick` (installed with the packages in section 5) rasterizes the SVG icons into a PNG cache.

> [!NOTE]
> Flow Icons' upstream README markets the extension as a premium theme ("demo icons only" without a license). The published `2.0.9` VSIX verified here ships the complete icon set per its own manifests — verify your license terms at https://flow-icons.pages.dev before reuse outside this setup.

## 9. Portable Standalone Vim Configuration (`.vimrc`)

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
- **Search and quickfix**: `<leader>fg` or `<leader>\` searches the project with `rg --vimgrep` or native `vimgrep`; `<leader>ff` searches normally using fuzzyfind with fzf if it's found in the system, otherwise it falls back to using find. Quickfix entries can be deleted with `dd` or Visual `d`, and `[q`/`]q` navigate the list.
- **Buffer and window navigation**: `H`/`L`, `[b`/`]b`, `<leader>b[`/`<leader>b]`, `<leader>bb`, and `<leader>bd` manage buffers; `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move between windows; `<leader>wd` closes the current window.
- **Line movement**: `<A-j>`/`<A-k>` and `<M-j>`/`<M-k>` move lines in Normal, Visual, and Insert modes with boundary checks. Terminal, Kitty, Windows Terminal, and tmux keycode compatibility mappings are included.
- **Git and diff helpers**: `<leader>bc` compares two open buffers; `<leader>gd` opens a Git index diff; `<leader>gb` opens a 35-column blame sidebar; `<leader>gH` shows file history; `[h`/`]h` navigate Git hunks; `<leader>ghp` previews a hunk; and `<leader>ghr` resets the current hunk.
- **Git signs and file helpers**: Modified lines receive add/change/delete signs, symlinks are followed on read, file MIME type is cached for the statusline, and system commands run through a stderr-suppressing wrapper.
- **Netrw explorer**: `<leader>e` toggles a banner-free tree at the current file’s directory and `<leader>fe` opens Netrw directly. Inside Netrw, `a`, `r`, and `d` create, rename, and delete entries.
- **Completion and spelling**: Insert-mode arrow keys navigate the completion menu, `<Tab>` confirms suggestions, and completion can trigger after matching words. `<leader>uo` toggles spelling with English dictionary; `[s` and `]s` navigate spelling errors.
- **Automatic integrations**: Autocommands refresh Git status and signs, restore the last cursor position, apply filetype-specific indentation/comment settings, configure Quickfix and Netrw buffers, sync yanks through `wl-copy`, and keep the completion and whitespace helpers updated.

---

## 10. MJML Support

[MJML](https://mjml.io) (Mailjet Markup Language) is supported out of the box for `.mjml` files, wired up in `lua/plugins/mjml.lua`.

- **Filetype & syntax:** `.mjml` files are detected as the dedicated `mjml` filetype. Neovim has no official MJML treesitter parser, so that filetype is registered against the existing **Blade** parser (`vim.treesitter.language.register("blade", "mjml")`). Blade is used rather than HTML because Laravel MJML templates contain Blade expressions and the plain `html` grammar treats a bare `>` inside text as fatal — every `->` wraps the whole document in a single `ERROR` node, leaving no tag/attribute nodes to colour (the symptom: highlighting appears to "stop" after the first lines). Blade is an HTML superset that parses those expressions and keeps the element tree intact. This gives full syntax highlighting, Blade directive highlighting, smart indentation, code folding and vim-matchup tag matching. CSS injection inside `<mj-style>` is added on top of the stock HTML query set by `after/queries/html/injections.scm` (the bundled queries only inject into `<style>`/`<script>`); Blade inherits the HTML queries, so the same file applies.
- **Editors & tools:** `ts-autotag.nvim` auto-closes and live-renames MJML tags (`lua/plugins/autotag.lua`), the comment string is set to `<!-- %s -->` (`lua/config/autocmds.lua`), and tag rainbow-delimiter coloring is silenced for MJML to stay consistent with HTML/XML (`lua/plugins/rainbow.lua`).
- **No language server:** MJML publishes no standalone language server, so no LSP is attached. Compiling/previewing emails is done outside Neovim via the `mjml-cli` npm package (not installed by this module).
- **Formatting:** Prettier has no native MJML parser, so it is intentionally **not** wired into `conform.nvim`. If you want formatting anyway, add a formatter entry that forces the HTML parser (`--parser html`) — verify it against your templates first, as Prettier's whitespace handling can affect rendered email output.
- **Not used:** the community `tree-sitter-mjml` grammars were deliberately skipped; they are unmaintained, and the most prominent one is explicitly marked "DO NOT USE" upstream.

> [!NOTE]
> The `mjml` filetype is mapped to the `blade` treesitter language, and the `blade` parser is already installed by `lua/plugins/laravel.lua` (`ensure_installed`), so no extra parser download (`:TSInstall`) is required.
>
> Custom query files under `after/queries/html/` must begin with a `; extends` (or `; inherits:`) modeline. Neovim silently discards a query file that lacks one once a base query for that language/query already exists. Blade inherits the HTML queries, so `after/queries/html/injections.scm` applies to `.mjml` as well.
