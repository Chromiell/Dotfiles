# Third-Party Notices

This repository is licensed under the MIT License (see [`LICENSE`](./LICENSE))
**except** for the bundled third-party components listed below. Those
components remain under their respective upstream licenses, and their original
copyright and license notices are preserved.

If you redistribute this repository, keep the referenced `LICENSE` files and
notices in place.

---

## LazyVim (Neovim configuration)

- **Path:** `neovim/.config/nvim/**`
- **License:** Apache License 2.0
- **License file:** `neovim/.config/nvim/LICENSE`
- **Upstream:** https://github.com/LazyVim/LazyVim

The Neovim configuration is based on the LazyVim starter template. The Apache
License 2.0 permits use, modification, and redistribution provided that the
license text and attribution notices are retained and modified files are marked
as changed. Any modifications made in this repository are provided under the
repository's MIT License, while the LazyVim-derived portions remain under
Apache-2.0.

> Note: `neovim/.config/nvim/README.md` still carries the original LazyVim
> starter-template heading and is retained as attribution.

---

## Addy Osmani `agent-skills` (simplify skill)

- **Path:** `opencode/.config/opencode/skills/simplify/**`
- **License:** MIT License
- **Copyright:** Copyright (c) 2025 Addy Osmani
- **Upstream:** https://github.com/addyosmani/agent-skills (`skills/code-simplification`)

The `simplify` skill is adapted from Addy Osmani's `code-simplification` skill.
The MIT License requires that the original copyright notice and permission
notice be retained with copies or substantial portions of the software. The
upstream MIT LICENSE is available in the upstream repository at the link above.

---

## Runtime-installed dependencies (not distributed)

The following are **not tracked** in this repository and are installed at
runtime by their own tooling. Their licenses therefore do not apply to the
distributed repository contents:

- Zsh plugins under `zsh/.config/zsh/` (Znap, Powerlevel10k and its gitstatus,
  zsh-autocomplete, fast-syntax-highlighting, zsh-history-substring-search, Deja)
- Tmux plugins under `tmux/.config/tmux/plugins/` (tpm, tmux)
- PHP packages under `composer/.config/composer/vendor/`
