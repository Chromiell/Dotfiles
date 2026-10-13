# Continuous Integration

GitHub Actions workflows that lint and sanity-check this repository on every push
to `main`, on every pull request, and on demand via **Run workflow**.

> [!NOTE]
> This file is intentionally **not** named `README.md`. GitHub prefers
> `.github/README.md` over the root `README.md` when choosing what to render on the
> repository home page, which would hide the main project README. Keeping the
> filename `CI.md` avoids that override.

---

## 📦 Required Tools

Nothing needs to be installed on the runner beyond the stock `ubuntu-latest`
image. Each linter runs through its official marketplace action, pinned to a full
commit SHA; GNU Stow and ShellCheck come from `apt`. Dependabot keeps the action
pins current (see [`dependabot.yml`](./dependabot.yml)).

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
| [`pythonScripts`](../pythonScripts) | Linting target | Python files are checked by Ruff. |
| all modules | Layout check | The `stow` job stows every package into a temporary `$HOME` and asserts the resulting symlinks resolve back into the checkout. |

---

## 📂 Structure

- `workflows/ci.yml`: the CI workflow. Jobs: `shellcheck`, `secrets`, `spelling`,
  `links`, `lua`, `python`, `stow`, and `notify` (run-status alerts).
- `dependabot.yml`: weekly Dependabot updates for the GitHub Actions used by
  `ci.yml` (each pinned by commit SHA).
- `linters/`: tool configuration consumed by the workflow — `linters/typos.toml`
  (spell-check allow-list) and `linters/ruff.toml` (Python lint rules). These live
  here rather than at the repository root to keep the top level uncluttered, and
  are read explicitly with each tool's `--config` flag.

---

## 🔒 Supply-chain & Version Pinning

- The repository is checked out with [`actions/checkout`](https://github.com/actions/checkout)
  pinned to a commit SHA, not a floating tag.
- Every linter action (`gitleaks-action`, `crate-ci/typos`, `lychee-action`,
  `stylua-action`, `ruff-action`) is likewise pinned to a full commit SHA, so a
  moved or deleted tag cannot change what runs.
- [Dependabot](./dependabot.yml) opens a weekly PR whenever one of those pinned
  SHAs moves — that is how the tools are kept up to date.
- The workflow only requests `contents: read`. The `secrets` job additionally
  requests `pull-requests: read`, which `gitleaks-action` uses.

### Updating a tool

Merge the corresponding Dependabot PR. The tool version follows the action:
`lychee-action` bundles its own lychee release, and `stylua-action` is configured
with `version: latest` so StyLua tracks its latest release while Dependabot tracks
the action itself. ShellCheck tracks the runner image through `apt`.

---

## 🔔 Notifications

A `notify` job reports the outcome of **every completed run** — pass or fail — to a
Discord or Slack incoming webhook. It gates on `if: !cancelled()`, so runs superseded
by a newer push stay silent, but otherwise both successful and failed runs are
announced. The message lists every job with a status icon — ✅ pass, ❌ fail, plus
marks for other states — and links to the run.

**Setup**

1. Create an incoming webhook — Discord: *Server Settings → Integrations → Webhooks*;
   Slack: *Apps → Incoming Webhooks*.
2. Add its URL as a repository secret named **`CI_WEBHOOK_URL`**
   (*Settings → Secrets and variables → Actions → New repository secret*). The URL is
   never stored in the repository.
3. Nothing else to configure — the job detects Slack (`hooks.slack.com`) and otherwise
   uses the Discord payload format.

The webhook is optional: with no secret set (for example, on pull requests from forks,
which never receive secrets) the step is skipped, so CI still runs untouched.

### Testing a failure

The workflow also has a manual **Run workflow** trigger (Actions → *CI* →
**Run workflow**) with a **simulate_failure** checkbox. Tick it to make the
`shellcheck` job fail on purpose and confirm the failure notification arrives; run
again unticked to see the pass message. The forced failure only applies to manual
runs — normal pushes and pull requests are unaffected.

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
mkdir -p "$fake_home/.local/bin" "$fake_home/Documents" "$fake_home/Project"
bash -c "shopt -u dotglob; stow -t '$fake_home' */"
```

> **Ruff cache.** Running `ruff` locally writes a self-ignoring `.ruff_cache/`
> directory. Pass `--no-cache` (or set `RUFF_CACHE_DIR`) to keep it off the root.

> **Offline link checking.** `lychee` runs with `--offline`, so it validates
> relative links and anchors only. This keeps CI deterministic and immune to
> third-party sites being slow or down; external links are not fetched.
