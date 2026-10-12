# Continuous Integration

GitHub Actions workflows that lint and sanity-check this repository on every push
to `main` and on every pull request.

> [!NOTE]
> This file is intentionally **not** named `README.md`. GitHub prefers
> `.github/README.md` over the root `README.md` when choosing what to render on the
> repository home page, which would hide the main project README. Keeping the
> filename `CI.md` avoids that override.

---

## 📦 Required Tools

Nothing needs to be installed on the runner beyond the stock `ubuntu-latest`
image. Each job downloads its linter as a pinned release binary and verifies it
against a pinned SHA-256; GNU Stow and ShellCheck come from `apt`. The pinned
versions live in the `env:` block of [`workflows/ci.yml`](./workflows/ci.yml).

| Tool | Job | Purpose |
| :--- | :--- | :--- |
| [ShellCheck](https://www.shellcheck.net/) | `shellcheck` | Lint every tracked shell script (shebang-based discovery). |
| [gitleaks](https://github.com/gitleaks/gitleaks) | `secrets` | Fail if a secret is committed. |
| [typos](https://github.com/crate-ci/typos) | `spelling` | Spell-check documentation and comments (config: `linters/typos.toml`). |
| [lychee](https://github.com/lycheeverse/lychee) | `links` | Validate relative Markdown links and anchors (offline). |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | `lua` | Check Lua formatting (config: `neovim/.config/nvim/stylua.toml`). |
| [Ruff](https://docs.astral.sh/ruff/) | `python` | Lint the Python controller macro (config: `linters/ruff.toml`). |
| [GNU Stow](https://www.gnu.org/software/stow/) | `stow` | Stow every package into a throwaway `$HOME` and verify the layout. |

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`scripts`](../scripts) | Linting target | Shell scripts are checked by ShellCheck. |
| [`neovim`](../neovim) | Linting target | Lua files are checked by StyLua. |
| [`controllerMacros`](../controllerMacros) | Linting target | Python files are checked by Ruff. |
| all modules | Layout check | The `stow` job stows every package into a temporary `$HOME` and asserts the resulting symlinks resolve back into the checkout. |

---

## 📂 Structure

- `workflows/ci.yml`: the CI workflow. Jobs: `shellcheck`, `secrets`, `spelling`,
  `links`, `lua`, `python`, `stow`.
- `dependabot.yml`: weekly Dependabot updates for the GitHub Actions themselves.
- `linters/`: tool configuration consumed by the workflow — `linters/typos.toml`
  (spell-check allow-list) and `linters/ruff.toml` (Python lint rules). These live
  here rather than at the repository root to keep the top level uncluttered, and
  are read explicitly with each tool's `--config` flag.

---

## 🔒 Supply-chain & Version Pinning

- The repository is checked out with [`actions/checkout`](https://github.com/actions/checkout)
  pinned to a commit SHA, not a floating tag.
- Linter binaries are downloaded from their official GitHub releases and verified
  against a pinned **SHA-256** before installation, so a substituted release
  cannot run.
- The workflow only requests `contents: read`.

### Bumping a tool

The linter versions are intentionally **not** managed by Dependabot (they are
plain version strings plus checksums, not actions). To bump one:

1. Update the matching `*_VERSION` and `*_SHA256` values in `workflows/ci.yml`.
2. Compute the checksum of the new release archive, for example:
   ```bash
   curl -fsSL <release-url> | sha256sum
   ```
3. Open a pull request — the workflow re-verifies the checksum on the next run.

---

## 🚀 Running the Checks Locally

Each check can be reproduced locally; the commands mirror the workflow steps:

```bash
# ShellCheck (shebang-based discovery, identical to CI)
git grep -lzI -E '^#!.*(bash|/sh)\b' | xargs -0 shellcheck --severity=warning

# Spelling, links, Lua formatting, Python
typos --config .github/linters/typos.toml
lychee --offline --no-progress --include-fragments '**/*.md'
stylua --check neovim/.config/nvim/lua
ruff check --config .github/linters/ruff.toml .

# Stow layout sanity check
fake_home="$(mktemp -d)"
mkdir -p "$fake_home/.local/bin" "$fake_home/Documents"
bash -c "shopt -u dotglob; stow -t '$fake_home' */"
```

> **Ruff cache.** Running `ruff` locally writes a self-ignoring `.ruff_cache/`
> directory. Pass `--no-cache` (or set `RUFF_CACHE_DIR`) to keep it off the root.

> **Offline link checking.** `lychee` runs with `--offline`, so it validates
> relative links and anchors only. This keeps CI deterministic and immune to
> third-party sites being slow or down; external links are not fetched.
