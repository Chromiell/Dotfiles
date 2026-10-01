# AGENTS.md

Guidance for AI coding agents working in this repository.

---

## What This Repository Is

This is a **GNU Stow-managed dotfiles repository** for **Debian-based systems**. Its goal is to provide a modular, reproducible, and version-controlled personal development environment: shell, terminal emulators, window manager, editor, CLI tools, container stacks, and administrative automation scripts.

The repository is the **source of truth** for these configurations. The live files under `$HOME` are **symlinks** created by GNU Stow that point back into this repository. Editing a file here changes the live configuration immediately; editing the live file edits this repository.

- **Remote:** `https://github.com/Chromiell/Dotfiles`
- **Default branch:** `main`
- **Target OS:** Debian / Ubuntu (some modules assume Wayland, X11, or containerized tooling)

### Core Model

Every **top-level directory is a Stow package**. Inside each package, the directory tree mirrors `$HOME`, so files land in the right place when stowed:

```
~/.dotfiles/<package>/.config/<app>/...   ->   ~/.config/<app>/...
~/.dotfiles/<package>/.zshrc              ->   ~/.zshrc
~/.dotfiles/<package>/.local/bin/...      ->   ~/.local/bin/...
```

Stow is invoked from the repository root:

```bash
cd ~/.dotfiles
stow <package>          # create symlinks
stow -D <package>       # remove symlinks (source files are kept)
stow -R <package>       # restow / refresh after adding files
bash -c 'shopt -u dotglob; stow */'   # stow every module at once
```

### Shared Directories

Most packages own an exclusive subtree of `$HOME`, so Stow folds them into a
single symlink. A few packages instead write into directories that are shared
with other packages or with runtime tools. Those directories **must exist as
real directories before stowing**; otherwise Stow folds the whole directory into
one symlink pointing into the repository, and runtime writers would write into
the repo:

```bash
mkdir -p ~/.local/bin ~/Documents
```

| Directory | Stow packages | Layout after stowing | Also written at runtime by |
| :--- | :--- | :--- | :--- |
| `~/.local/bin` | `scripts` | real dir, files symlinked | Deja, znap, distrobox, `uv` |
| `~/Documents` | `scripts`, `documents` | real dir; `Scripts/`, `ScriptsData/` and `Guides/` are symlinks | — |

Because `~/Documents` itself already exists, Stow folds its subdirectories
(`Scripts`, `ScriptsData`, `Guides`) into symlinks rather than real
directories.

---

## Repository Map

| Module | Category | Responsibility |
| :--- | :--- | :--- |
| `zsh/` | Shell | Zsh config split into numbered `00-startup` … `50-integrations` files, Znap plugin manager, Powerlevel10k prompt, aliases, functions. |
| `tmux/` | Multiplexer | Catppuccin Mocha tmux config, prefix-less navigation, status bar resource modules. |
| `neovim/` | Editor / IDE | LazyVim setup (run via an Arch Distrobox container), plus portable `.vimrc`, Yazi and Lazygit configs. Graphical file icons via `real-icons.nvim` (Flow Icons pack, installed by `lua/plugins/icons.lua` + `scripts/install-flow-icons.sh`). |
| `git/` | Version Control | `.gitconfig` include chain, global ignore, and `_template` files copied to real secret files. |
| `scripts/` | Automation | Admin, DB backup/sync, Certbot/HAProxy, deployment, and desktop utility scripts, stowed into `~/Documents/Scripts`, `~/Documents/ScriptsData` and `~/.local/bin`. Sensitive values live in gitignored `Documents/ScriptsData/config.env`. |
| `documents/` | Documentation | Personal technical guides, how-to notes, and reference documents stowed into `~/Documents/Guides`. |
| `alacritty/` | Terminal | GPU-accelerated terminal emulator config (TOML + legacy YAML). |
| `kitty/` | Terminal | Kitty config and startup session profiles. |
| `niri/` | Window Manager | Modular KDL config for the scrollable-tiling Wayland compositor (DMS sub-configs). |
| `eza/` | CLI Tool | Custom theme for the `ls` replacement. |
| `fastfetch/` | CLI Tool | System information display config. |
| `fzf/` | CLI Tool | Fuzzy finder config and preview helper scripts. |
| `dockerFiles/` | Containers | Docker Compose stacks: Bugsink, Docmost, Gitea, Mailpit, Watchtower. |
| `controllerMacros/` | Input / Gaming | Python controller button-swap and macro scripts. |
| `composer/` | Development | Global PHP Composer settings. |
| `php-cs-fixer/` | Development | PHP coding-standards / PSR fixer config. |
| `opencode/` | AI / Development | Token-optimized OpenCode CLI config plus the `oh-my-opencode-slim` orchestrator plugin. |
| `images/` | Assets | Shared wallpapers and media assets. |
| `mouseCursorDefault/` | Desktop | Default XDG cursor theme definitions. |

Each module also has its own `README.md` with package requirements, module dependencies, structure, and setup steps. Read the relevant module README before changing that module.

---

## Conventions & Guardrails

1. **Stow layout is mandatory.** Any new file must be placed under the correct package at the path it should occupy in `$HOME`. Do not add files that would collide with existing `$HOME` files.
2. **Never commit secrets.** Sensitive values (passwords, hosts, tokens, service passwords) must stay in gitignored files:
   - `scripts/Documents/ScriptsData/config.env` (template: `config.env.example`)
   - `git/.config/git/.git_credentials`, `.git_user`, `.git_ignore_global` (templates: `*_template`)
   - `opencode/.config/opencode/service.json` and `*.local.json[c]`
   Always keep the tracked template (`*.example` / `*_template`) in sync with new variables, using sanitized placeholders.
3. **Respect per-module `.gitignore` files.** They intentionally exclude secrets, machine-local overrides, and regenerated runtime state (e.g. `lazy-lock.json`, the oh-my-opencode-slim manifest). Do not force-add ignored files.
4. **Keep module READMEs accurate.** When changing a module's packages, structure, or dependencies, update that module's `README.md`.
5. **Dependencies are cross-module.** Many modules depend on the Adwaita Mono Nerd Font installed by `scripts/.local/bin/install-adwaita-nerd-font`, and on `zsh/` for aliases. When adding a dependency, document it in both modules' READMEs (see existing "Dotfiles Module Dependencies" tables).
6. **No destructive operations.** Do not delete user configuration, remove Stow packages, or rewrite live `$HOME` files unless explicitly asked.
7. **Match existing style.** Config files, scripts, and READMEs follow consistent formatting and section conventions — mirror them.
8. **Shared directories must exist before stowing.** `~/.local/bin` and `~/Documents` are written to by multiple packages and/or runtime tools. Create them first (see **Shared Directories**) so Stow links files into them instead of folding them into repo symlinks.

---

## Licensing

- Original work in this repository is under the **MIT License** (`LICENSE`).
- Bundled third-party components are **excluded** from that license and keep their own terms. Always preserve their notices and license files:
  - `neovim/.config/nvim/**` → Apache-2.0 (`neovim/.config/nvim/LICENSE`, LazyVim)
  - `opencode/.config/opencode/skills/simplify/**` → MIT, © Addy Osmani
- Full attribution lives in `THIRD-PARTY-NOTICES.md`. Update it (and the README License table) when you add or remove third-party/adapted content.
- Upstream dependencies installed at runtime (Zsh/Tmux plugins, Composer `vendor/`, the downloaded font binaries) are gitignored and not distributed, so their licenses do not apply to this repository.

---

## Maintaining This File

**Agents must keep this `AGENTS.md` current.** Whenever you add, remove, or meaningfully change something in this repository, update this file in the same change:

- **New module added** → add a row to the **Repository Map** table and a short description, and create/update its `README.md`.
- **Module removed or renamed** → remove or update its map row and any references here.
- **New top-level asset, script location, or convention** → document it in the relevant section (Repository Map, Conventions, or a new section).
- **Change to how the repo is installed, stowed, or structured** → update **What This Repository Is** / the Core Model.
- **New secret/template file** → add it to the **Never commit secrets** list.

Do not let this document drift from reality. If a change affects what an agent needs to know to work here safely and correctly, it belongs in `AGENTS.md`.
