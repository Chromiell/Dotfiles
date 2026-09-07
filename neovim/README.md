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

The `.vimrc` file is written in pure Vimscript with **zero external plugin dependencies**, functioning out-of-the-box on standard Vim (version 8.0+ or 9.0+) while replicating key features from this Neovim configuration:

- **TokyoNight Moon Theme & Highlights**: Full 24-bit TrueColor palette with dark background (`#222436`), syntax highlights, styled relative line numbers (`#636da6`), subtle whitespace indicators (`#3b4261`), and custom quickfix error/file colors.
- **Lualine-Style Dynamic Statusline**: Displays active mode indicator badges (`NORMAL`, `INSERT`, `VISUAL`, `REPLACE`, `COMMAND`), live Git branch name and uncommitted changes counter (`󰊢 <branch> (<count>)`), file path, modified/readonly flags, file encoding/format, and line/column metrics.
- **Trailing Whitespace Handling**: Subtle trailing space highlights with custom dark red background (`#681d23` / `#686868`, matching `mini.trailspace`), toggleable via `<leader>cT`, and trimmed with `<leader>ct` (file or visual selection).
- **Hex $\leftrightarrow$ HSL Color Converter (`<leader>co` / `:ToggleHexHsl`)**: Automatically converts color codes under the cursor between 6-digit Hex (`#RRGGBB`) and HSL (`hsl(H, S%, L%)`).
- **Timestamp $\leftrightarrow$ Date Converter (`<leader>cx`)**: Toggles visual selection between Unix epoch timestamps and human-readable `YYYY-MM-DD HH:MM:SS` dates.
- **Relative Project Path Utility (`<leader>fP`)**: Detects the project root (via `.git`, `package.json`, or `Makefile`) and copies the relative buffer path to system and unnamed registers.
- **Auto-Formatting & Indentation (`<leader>cf`)**: Formats the entire buffer in Normal mode or indents the current selection in Visual mode.
- **Project Search via Quickfix (`<leader>fg` / `<leader>\`)**: Interactively prompts for a search query and populates the Quickfix window using `ripgrep` (`rg --vimgrep`) if available, or native `vimgrep`.
- **Interactive Quickfix Editing (`dd` / visual `d`)**: Delete single entries with `dd` or multiple lines with `d` directly inside the Quickfix window, matching `quicker.nvim`.
- **Buffer & Window Navigation**:
  - Buffer cycling: `H` / `L`, `[b` / `]b`, `<leader>b[` / `<leader>b]`, list buffers with `<leader>bb`, and close with `<leader>bd`.
  - Window navigation: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`.
  - Visual indenting: `<Tab>` / `<S-Tab>` while preserving visual selection (`>gv` / `<gv`).
  - Move lines: `<A-j>` and `<A-k>` in Normal, Visual, and Insert modes.
- **Git & Diff Helpers**:
  - `<leader>bc`: Interactively diff any two open buffers in a new tab.
  - `<leader>gd`: Split diff against Git index.
  - `<leader>gb`: Open a 35-column Git blame sidebar for the current file.
  - `<leader>gH`: View Git commit history for the current file.
- **File Explorer & Spellchecking**:
  - `<leader>e` / `<leader>fe`: Toggle Netrw in a clean, banner-free tree view.
  - `<leader>uo`: Toggle spell checking (`en,it`), with typo navigation via `]s` and `[s`.

