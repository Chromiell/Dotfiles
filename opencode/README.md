# OpenCode Configuration

A token-optimized global [OpenCode](https://opencode.ai) configuration intended for
OpenCode Go / Zen (Console) subscriptions. It keeps junk directories out of indexing,
caps tool output and image sizes, compacts context earlier, and generates session
titles with a **free** model — while keeping API keys out of this public repository.

It also ships the [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim)
plugin, which turns OpenCode into an **orchestrator plus a team of specialist
subagents** running on the OpenCode Go subscription, and the
[opencode-tps-meter](https://github.com/ChiR24/opencode-tps-meter) plugin, which adds a
live tokens-per-second meter to the TUI ([section 6](#-6-live-throughput-meter-opencode-tps-meter)),
and the standalone [opencode-session-usage](https://github.com/Chromiell/opencode-session-usage)
sidebar plugin ([section 10](#-10-usage-sidebar)).

---

## 📑 Index

- [1. Install Node.js & OpenCode](#-1-install-nodejs--opencode)
- [2. Deploy Configuration with GNU Stow](#-2-deploy-configuration-with-gnu-stow)
  - [Fresh-machine checklist](#fresh-machine-checklist)
- [3. Configuration Structure](#-3-configuration-structure)
- [4. Token & Usage Optimizations](#-4-token--usage-optimizations)
- [5. Multi-Agent Setup (oh-my-opencode-slim)](#-5-multi-agent-setup-oh-my-opencode-slim)
  - [Active preset (`opencode-go`)](#active-preset-opencode-go)
    - [Orchestrator: decide and delegate](#orchestrator-decide-and-delegate)
    - [Oracle: planner and advisor](#oracle-planner-and-advisor)
  - [Marketplace agents](#marketplace-agents)
  - [Usage](#usage)
  - [Browser testing with `playwright-cli`](#browser-testing-with-playwright-cli)
  - [Desktop control with `desktop-use`](#desktop-control-with-desktop-use)
  - [Background subagents](#background-subagents)
  - [Using a single model instead](#using-a-single-model-instead)
  - [Updating](#updating)
- [6. Live Throughput Meter (opencode-tps-meter)](#-6-live-throughput-meter-opencode-tps-meter)
- [7. Secrets & Environment Variables](#-7-secrets--environment-variables)
- [8. MCP Servers](#-8-mcp-servers)
- [Related Modules](#-related-modules)
- [9. Editor Schema Warnings (Neovim)](#-9-editor-schema-warnings-neovim)
- [10. Usage Sidebar](#-10-usage-sidebar)

---

## 📦 1. Install Node.js & OpenCode

OpenCode is distributed as an npm package. The recommended way to manage Node.js is
[nvm](https://github.com/nvm-sh/nvm); install it in your base system, then install the
latest LTS version of Node.

Install OpenCode globally with npm:

```bash
npm install -g @opencode/cli
```

Verify the installation and the version (this configuration targets OpenCode **v2**):

```bash
opencode --version
```

---

## 🔗 2. Deploy Configuration with GNU Stow

From the dotfiles repository (assumed to be `~/.dotfiles`), stow the `opencode` package:

```bash
cd ~/.dotfiles
stow opencode
```

This folds the whole configuration directory into a single symlink:

- `~/.config/opencode` $\rightarrow$ `~/.dotfiles/opencode/.config/opencode`

> [!IMPORTANT]
> `service.json` is generated locally by OpenCode and contains a service password. It
> lives inside this module directory but is **never** committed — the module
> `.gitignore` excludes it.

### Fresh-machine checklist

Config files travel through Git, but a few things are per-machine:

1. `stow opencode` (and `stow zsh`, which provides the environment variables below).
2. `opencode auth login` and sign in to **OpenCode Go** — credentials live in
   `~/.local/share/opencode/opencode.db`, not in this repository.
3. Ensure the OpenCode env vars are present (they are in the tracked `zsh/.zshenv`
   once stowed — see [section 5](#-5-multi-agent-setup-oh-my-opencode-slim)).
4. Install the two marketplace agents. They are **not** vendored here and are not
   downloaded automatically by `stow` or by the plugin on first start:

   ```bash
   npx -y oh-my-opencode-slim@latest marketplace install alvin/paladin
   npx -y oh-my-opencode-slim@latest marketplace install alvin/documenter
   ```

   The tracked preset already selects both under `marketplace.agents_add`, so no
   `marketplace enable` step is needed.
5. The usage panel is installed from npm as `opencode-session-usage`,
   as described in [section 10](#-10-usage-sidebar).
6. `opencode service restart`, then confirm the plugin loaded with `opencode plugin list`.

`service.json`, the npm plugin cache (`~/.cache/opencode/npm`), plugin runtime
state, and session/credential data are recreated automatically. Marketplace agent
packages are the exception: they live in the shared store at
`~/.local/share/opencode/storage/oh-my-opencode-slim/marketplace/` and must be
installed once per machine as described above.

---

## 🧱 3. Configuration Structure

```text
~/.config/opencode/            → symlink to ~/.dotfiles/opencode/.config/opencode/
├── opencode.jsonc            # Tracked (stowed): global config, MCP servers, plugins
├── cli.json                  # Tracked: TUI-only settings + external usage-sidebar plugin
├── usage-sidebar.json        # Tracked: usage panel options (refresh, position, display)
├── oh-my-opencode-slim.json  # Tracked: multi-agent presets (opencode-go active)
├── gridcraft-mcp/            # Tracked: self-contained GridCraft MCP server
│   ├── server.mjs            #   live control channel / headless fallback
│   └── tools.json            #   tool schemas mirrored from GridCraft
├── wordcraft-mcp/            # Tracked: self-contained WordCraft MCP launcher
│   └── server.mjs            #   live control channel / headless fallback
├── skills/                   # Tracked: plugin skills + custom skills (playwright-cli, browser-use, desktop-use)
└── service.json              # Local service password (git-ignored)
```

`opencode.jsonc` is **JSONC**, so it supports comments and trailing commas.
`cli.json` is **strict JSON** (no comments) and holds terminal-only preferences,
which are separate from the server/project config in `opencode.jsonc`. For example,
`"prompt": { "paste": "full" }` shows pasted text in full instead of a
`[Pasted ~N lines]` placeholder so it can be edited in the prompt input (set it to
`"compact"` to restore the placeholder). Valid edits reload while the TUI is running.

> [!NOTE]
> Older plugin releases wrote a `.oh-my-opencode-slim/` skills manifest in this
> directory. Current releases register bundled skills in-process and remove that
> legacy directory; runtime state (TUI state and the marketplace package store)
> lives under `~/.local/share/opencode/storage/oh-my-opencode-slim/`. Nothing
> under `~/.config/opencode` needs restoring by hand.

---

## ⚡ 4. Token & Usage Optimizations

| Setting | Value | Why |
| :--- | :--- | :--- |
| `agents.title.model` | `opencode/mimo-v2.6-flash-free` | Session titles are generated by a **free** model instead of a paid one (Haiku / Nano / Flash). |
| `tool_output` | 1000 lines / 45 KB | Truncates tool results before they enter the context; the full output is still saved to disk. Stays below the `read` tool's own 2000-line / 50 KiB page so ordinary file reads arrive in one call. |
| `media.image` | 1600×1600, 2 MiB | Resizes oversized image attachments before they reach the model. |

**Compaction is deliberately left at its defaults** (`keep.tokens: 15000`,
`auto: true`, and an implicit `buffer` of 15% of the model window, minimum 16k).
It triggers when the estimated next request approaches the model's context
window, not every N tokens: on a 1M-token model (DeepSeek V4.1 Flash) that is
around 850k tokens, so most sessions never compact. A smaller `buffer` pushes the
trigger to the edge and leaves no room for the summary, which then has to drop
older exchanges.

**`watcher.ignore` was removed.** It only filters filesystem-watch events and
does not affect what `glob`, `grep`, or `read` can see, so it saved no tokens.
Search exclusion belongs in a repository's `.gitignore` or a ripgrep `.ignore`
file, both of which the tools already honour.

The free model lineup changes over time. Confirm what your account offers with
`opencode models` (or `/models` in the TUI) and update `agents.title.model` if needed.

---

## 🧠 5. Multi-Agent Setup (oh-my-opencode-slim)

The plugin is loaded by both the server and the TUI from the `plugins` array in
`opencode.jsonc`:

```jsonc
"plugins": [
  "@tarquinen/opencode-dcp@latest",
  "oh-my-opencode-slim",
  { "package": "opencode-tps-meter@latest", "options": { /* see section 6 */ } }
]
```

OpenCode resolves the plugin from npm on first start, so no install step is
needed for the plugin itself. Marketplace agent packages are separate: they are
not downloaded automatically and must be installed once per machine (see
[Marketplace agents](#marketplace-agents)). `oh-my-opencode-slim`'s behavior is
configured in `oh-my-opencode-slim.json`,
which defines two model presets — **`opencode-go` is active**, and `openai` is kept
for quick switching with the `/preset` command.

### Active preset (`opencode-go`)

The mapping below was chosen per role for the best fit/price trade-off on the Go
subscription (prices are USD per million tokens, in/out):

| Agent | Model | Variant | Rationale |
| :--- | :--- | :--- | :--- |
| orchestrator (primary) | `opencode-go/deepseek-v4-pro` | `max` | Strong reasoning + instruction-following (needed for reliable delegation) at $0.66/$1.98; 1M ctx, cheap cache reads. No custom role append or edit-deny permission is applied; heavy multi-phase work goes through the `/deepwork` skill. |
| oracle | `opencode-go/deepseek-v4-pro` | `max` | Strongest high-reasoning on Go at $0.66/$1.98 — ~4× cheaper than `qwen3.7-max`. |
| explorer | `opencode-go/deepseek-v4.1-flash` | `high` | Fast model with higher reasoning for codebase recon plus external docs and web research (`context7`, `gh_grep`, `websearch`); 1M ctx, vision, $0.15/$0.60. |
| designer | `opencode-go/deepseek-v4.1-flash` | `max` | Same fast, vision-capable model as explorer but at max reasoning for UI/UX and frontend polish; $0.15/$0.60. |
| fixer | `opencode-go/deepseek-v4.1-flash` | `high` | Reliable scoped coding at the lowest cost tier. |
| observer | `opencode-go/mimo-v2.6-flash` | *(none)* | Paid Go variant of the same MiMo flash model; vision-capable at $0.14/$0.28, so visual analysis stays within the Go subscription. |
| council (synthesiser) | `opencode-go/deepseek-v4-pro` | `max` | Strong synthesiser; council is manual/high-cost. |
| councillor-alpha | `opencode-go/deepseek-v4-pro` | `max` | DeepSeek perspective. |
| councillor-beta | `opencode-go/qwen3.8-max` | `xhigh` | Qwen perspective (different model family). |
| councillor-gamma | `opencode-go/glm-5.3` | `high` | GLM perspective (different model family). |

> [!TIP]
> **Subagents can reach `@observer` too.** `explorer`, `oracle` and `designer`
> carry a `task` permission of `{"*": "deny", "observer": "allow"}`, so a
> screenshot or diagram found mid-reconnaissance can be described by the vision
> model without routing back through the orchestrator. OpenCode rejects nested
> subagents at its default depth of 1, so `opencode.jsonc` sets
> `"experimental": { "subagent_depth": 2 }` — exactly one extra hop. `fixer`,
> `observer` itself and the council synthesiser keep deny-all `task` maps and
> stay non-spawning.

> [!NOTE]
> **`librarian` was merged into `explorer`** in oh-my-opencode-slim 3.0.5
> ([PR #1581](https://github.com/alvinunreal/oh-my-opencode-slim/pull/1581)), so there is
> no separate `@librarian` subagent. `explorer` now owns both codebase recon and
> external docs/library research (`context7`, `gh_grep`). Legacy `librarian` config
> keys and `librarian_append.md` files still alias to explorer, but canonical
> `explorer` fields win per-field. This config uses `explorer` directly and lists its
> MCPs explicitly (`context7`, `gh_grep`, `websearch`): the plugin's explorer default is
> only `context7` + `gh_grep`, so `websearch` must be named to give explorer Exa web
> search in addition to fetching known URLs.

The **council** exists only because a top-level `council` block is present in
`oh-my-opencode-slim.json`; delete that block to remove `@council` entirely. It is
never auto-delegated and runs three parallel frontier councillors plus a synthesiser,
so treat it as a deliberate, higher-cost escalation.

#### Orchestrator: decide and delegate

The orchestrator is the plugin's built-in primary agent: it plans, delegates,
monitors, reconciles, and verifies specialist work. Upstream also lets it act
directly when it already holds the needed context, the change is small and clear,
or the work is mostly context (docs, changelogs, summaries) — a fresh delegate
would have to rediscover that context.

Append prompts remain the supported tuning mechanism if a local override is
needed later: `{agent}_append.md` files live in
`~/.config/opencode/oh-my-opencode-slim/` (or a `{preset}/` subdirectory for
preset-specific tuning) and are added *after* the built-in prompt, unlike
`agents.<name>.prompt` in config which *replaces* it. No such override files are
shipped in this repository.

> [!WARNING]
> Upstream presets are generated by the installer and are often **outdated**. The
> bundled `opencode-go` preset assigned `"variant": "max"` to the oracle on
> `qwen3.7-max`, but that model exposes **no variants**, so OpenCode aborted every
> oracle child session with
> `SessionRunnerModel.VariantUnavailableError: Variant unavailable for opencode-go/qwen3.7-max: max`.
> The preset was re-audited and every model/variant pair below was checked against
> the provider. A model only accepts variants OpenCode actually exposes — verify
> before trusting any preset. List them with `opencode api get /api/model`
> (the `variants` field), or pick a model/variant in `/models`.

#### Oracle: planner and advisor

`@oracle` is the plugin's built-in high-reasoning advisor, configured here as
`opencode-go/deepseek-v4-pro` at `max` with the `simplify` skill. Consult it for
architecture, approach, hard-bug, and debugging decisions.

### Marketplace agents

Two marketplace agents are **selected** by the active `opencode-go` preset in the
user-level plugin config (`~/.config/opencode/oh-my-opencode-slim.json`, not a
project-local `.opencode/` override):

- **`alvin/paladin`** v1.0.1 — standalone, read-only security reviewer.
- **`alvin/documenter`** v1.0.0 — documentation architect with documentation-only
  write authority.

`marketplace.agents_add` only activates a package; it does **not** download one.
There is no auto-install hook: GNU Stow only creates symlinks, and the plugin
resolves the configured package IDs at startup but never downloads missing
packages. The packages are not vendored in this repository, and `stow opencode`
only links the config. On a new machine, install them once **before** opening
OpenCode:

```bash
npx -y oh-my-opencode-slim@latest marketplace install alvin/paladin
npx -y oh-my-opencode-slim@latest marketplace install alvin/documenter
```

Then restart OpenCode (`opencode service restart`). No `marketplace enable` step is
needed because the tracked preset already lists both packages. If OpenCode is
started first, the agents are absent; `marketplace status` reports
`alvin/... is not installed` until they are installed.

Alternatively, ask the orchestrator to install them; it exposes the
`marketplace_manage` tool. Marketplace packages live in the shared store at
`~/.local/share/opencode/storage/oh-my-opencode-slim/marketplace/`, outside Stow
and Git.

A top-level `agents` block in the same file pins each one's model and variant under
its runtime name (`paladin`, `documenter`):

| Agent | Model | Variant | Role |
| :--- | :--- | :--- | :--- |
| `paladin` | `opencode-go/deepseek-v4-pro` | `max` | Read-only security review |
| `documenter` | `opencode-go/deepseek-v4.1-flash` | `low` | Documentation-only edits |

Their versions follow what the marketplace serves; the versions above are the ones
installed when they were enabled. Update them with `marketplace update <id>` and
restart OpenCode.

### Usage

- `build` is pinned as the default primary agent in `opencode.jsonc`
  (`"default_agent": "build"`). The plugin would otherwise auto-select its
  orchestrator, but it only does so when `default_agent` is unset or points at a
  subagent, so the explicit value wins and a fresh session is plain single-model
  OpenCode. Switch to the team per session with `shift+tab` (cycles
  `build` → `plan` → `orchestrator`).
- The **orchestrator** delegates automatically once selected.
- Delegate explicitly with `@explorer`, `@fixer`, `@oracle`, `@designer`,
  `@council`, `@observer`, `@paladin`, or `@documenter`.
- Skills: `/deepwork <task>`, `run codemap`, `/reflect`, `work in a worktree`,
  `clone dependencies`, `playwright-cli` (browser automation), and `desktop-use`
  (local GUI automation).
- Swap the whole team's models at runtime with `/preset` (reload to apply).
- Verify delegation with `ping all agents`.

### Browser testing with `playwright-cli`

A custom `playwright-cli` skill (tracked at `skills/playwright-cli/SKILL.md`) wraps
the globally installed `@playwright/cli`, letting agents drive a real browser from the
shell. Ownership follows the normal role split: **`@designer`** drives it for
UI/visual verification, **`@fixer`** for automated test suites, **`@explorer`** for
read-only page reconnaissance, and **`@observer`** analyses the resulting screenshots.
The skill documents the session model (`-s=<session>`), the open → snapshot →
interact → verify workflow, and the full command reference.

### Desktop control with `desktop-use`

A custom `desktop-use` skill (tracked at `skills/desktop-use/`) lets an agent
drive the **local** desktop — the same Wayland/niri screen a human sees — for GUI
apps, game launchers, and native dialogs (browsers still go through
`playwright-cli`). It ships `SKILL.md` plus a helper at
`skills/desktop-use/scripts/desktop-use` that wraps `grim` (screenshots),
`ydotool` (pointer/keyboard), and `niri msg` (windows).

The helper encapsulates the two error-prone primitives: pointer movement
(clamp-to-origin + relative move, because `ydotool --absolute` overshoots under
pointer acceleration) and region-scoped cursor detection (a full-screen
`grim -c` diff is corrupted by animated content). The skill documents the closed
loop — screenshot, read the PNG, act, verify — plus the grim/ydotool/niri
gotchas learned from real use.

The primary `build`/`plan` agents and the orchestrator (`skills: ["*"]`) load it
automatically; to let a specialist drive the desktop, add `desktop-use` to that
agent's `skills` list in `oh-my-opencode-slim.json`. Prerequisites are `grim`,
`ydotool` (with `ydotoold` running), `niri`, `imagemagick`, and `jq`; check with
`~/.config/opencode/skills/desktop-use/scripts/desktop-use info`.

### Background subagents

Two environment variables (in the tracked [`zsh`](../zsh) module's `.zshenv`) enable
the orchestrator's parallel background work:

```bash
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true  # native V2 async subagent sessions
export OPENCODE_ENABLE_EXA=1                            # built-in Exa web search, no key needed
```

The background OpenCode service reads these at startup, so `opencode service restart`
after adding a new shell. The plugin exposes `task_status`, `task_result`,
`task_message`, `task_cancel`, `task_revive`, and `wait_for_user` to track background
tasks.

### Using a single model instead

- Per session: `build` is already the default (see above); `shift+tab` cycles
  between `build`, `plan`, and the plugin's primary agents.
- One shot: start OpenCode with `OH_MY_OPENCODE_SLIM_DISABLE=1 opencode`.
- Permanently: comment out `"oh-my-opencode-slim"` in the `plugins` array and run
  `opencode service restart`.

### Updating

| Layer | Command |
| :--- | :--- |
| OpenCode | `opencode upgrade` |
| Plugin | Auto-updates by default (`autoUpdate: true`); manual: `opencode plugin check` then `opencode plugin update`. |
| Bundled skills | Registered in-process when the plugin loads; restart OpenCode after a plugin update. |
| Marketplace agents | `npx -y oh-my-opencode-slim@latest marketplace update <id>` for each installed package, then restart OpenCode. |

Apply config changes with `opencode reload`; apply plugin code changes with
`opencode service restart`.

> [!NOTE]
> Prefer hand-editing `opencode.jsonc`. `opencode plugin add/remove` may re-serialize
> the file and **strip its comments**. Use `opencode plugin update` for version bumps.

---

## 📊 6. Live Throughput Meter (opencode-tps-meter)

The [opencode-tps-meter](https://github.com/ChiR24/opencode-tps-meter) plugin renders a
live tokens-per-second readout beside the prompt while the model streams. While tokens
are flowing, the leading figure is the rolling instant rate; once the turn settles it
switches to the session average, so a frozen meter reads as a summary rather than a
stale live value. Final totals always come from the provider-reported token counts, so
they are exact rather than estimated.

It is configured in two places with identical values: inline in the `plugins` array of
`opencode.jsonc` (the commented block documents every option) **and** in the plugin's
own `tps-meter.json` under this directory. The global file is the reliable source: the
plugin reads `~/.config/opencode/tps-meter.json` directly, whereas the inline `options`
may not reach the TUI half on every build. The options produce a compact footer format
with instant/average TPS, total tokens and elapsed time, TPS-based color coding
(red < 10 t/s, yellow 10–50, green > 50), and a 1.5 s rolling window.
`updateIntervalMs` is deliberately left unset — keeping the default value selects the
plugin's fast 8 ms V2 TUI refresh instead of the 50 ms fallback.

`tps-meter.json` must be **strict JSON** (no comments, no trailing commas): the plugin
parses it with `JSON.parse` and silently ignores the whole file on any error.

| Command | Effect |
| :--- | :--- |
| `/tps` | Open the throughput dashboard: per-model mean/best t/s, mean TTFT and step count, backed by a durable ledger. |
| `/tps detail` | Toast with per-session t/s, tokens, generation rate (tool time excluded), TTFT, and title/compaction overhead. |
| `/tps reset` | Clear the durable per-model ledger. |
| `/tps detailed` | Footer detail mode: adds generation rate, TTFT, overhead and an `aborted` marker to the meter line. |
| `/tps hidden` / `/tps compact` | Hide the footer meter / restore the compact line. |

When the active session has subagent children (e.g. the orchestrator's specialists), a
per-subagent throughput breakdown appears in the sidebar automatically.

Inline options win over the plugin's other configuration sources (project
`.opencode/tps-meter.json` < global `~/.config/opencode/tps-meter.json` <
`TPS_METER_*` environment variables < inline `options`). Apply option changes with
`opencode reload`.

> [!NOTE]
> **Color coding does not render on OpenCode 2.0.24+.** The released plugin (v0.4.0)
> resolves its colors from old theme token names (`text.default`, `text.subdued`,
> `text.feedback.*.default`) that V2 no longer exposes, so every branch returns
> `undefined` and the meter falls back to the default (white) foreground — even with
> `enableColorCoding: true` and the thresholds above. The fix is upstream
> [PR #10](https://github.com/ChiR24/opencode-tps-meter/pull/10); until it is merged and
> released, only the text/elapsed options apply. Revisit this section after the next
> `opencode plugin update`.

---

## 🔑 7. Secrets & Environment Variables

No secrets are stored in this repository. `opencode.jsonc` reads the Exa web search
key from the environment using OpenCode's `{env:...}` substitution:

```jsonc
"headers": {
  "x-api-key": "{env:EXA_API_KEY}"
}
```

Export the value in `~/.zshadditions` (untracked, sourced by the
[`zsh`](../zsh) module):

```bash
export EXA_API_KEY="your-exa-api-key"
```

Non-secret OpenCode variables (background subagents, Exa web search) live in the
tracked `zsh/.zshenv` so they travel with the dotfiles — see
[section 5](#-5-multi-agent-setup-oh-my-opencode-slim).

Then open a new shell and restart the OpenCode service so it inherits the variables:

```bash
opencode service restart
```

> [!NOTE]
> The background OpenCode service reads environment variables when it starts. If
> `EXA_API_KEY` is unset, the web search MCP server receives an empty key and will not
> work until the service is restarted from a shell that has it.

---

## 🧩 8. MCP Servers

| Server | Type | Purpose | Secret |
| :--- | :--- | :--- | :--- |
| `context7` | Remote | Up-to-date library / framework documentation | None |
| `grep-app` | Remote | GitHub code search | None |
| `websearch` | Remote (Exa) | Real-time web search | `EXA_API_KEY` |
| `gridcraft` | Local (Node) | GridCraft spreadsheets — live GUI workbook or bundled headless engine | None |
| `wordcraft` | Local (Node) | WordCraft documents — live GUI document or bundled headless engine | None |

> `gridcraft` and `wordcraft` are configured with `"disabled": true`, so they
> stay unconnected by default and cost nothing until you need them. Enable one
> by hand — remove its `"disabled"` line in `opencode.jsonc` (or toggle it in
> the client) and restart the service.

### GridCraft

The GridCraft MCP server is tracked in `gridcraft-mcp/` and is fully
self-contained: there are no helper scripts in `~/.local/bin`. It requires the
GridCraft AppImage (default `~/AppImages/gridcraft.appimage`).

- If GridCraft is running with its control channel (`gridcraft.appimage --control 7979`),
  the server talks directly to the live GUI workbook over TCP.
- Otherwise, it extracts the `gridcraft-cli` bundled inside the AppImage to
  `~/.cache/gridcraft-mcp/` on first use and runs the headless engine. The cache is
  refreshed automatically when the AppImage changes.

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `GRIDCRAFT_PORT` | `7979` | Control-channel port |
| `GRIDCRAFT_APPIMAGE` | `~/AppImages/gridcraft.appimage` | AppImage location |
| `GRIDCRAFT_MODE` | auto | Force `direct` or `headless` |
| `GRIDCRAFT_TIMEOUT` | `120000` | Control-request timeout (ms) |

After changing the config, run `opencode reload` (or restart the service) so the
new command is picked up.

### WordCraft

The WordCraft MCP server is tracked in `wordcraft-mcp/` and follows the same
self-contained pattern. It requires the WordCraft AppImage (default
`~/AppImages/wordcraft.appimage`) and no helper scripts.

- If WordCraft is running with its control channel
  (`wordcraft.appimage --control 7979`), the launcher starts the bundled
  `wordcraft-cli` in bridge mode and operates on the live GUI document.
- Otherwise it extracts `wordcraft-cli` from the AppImage to
  `~/.cache/wordcraft-mcp/` on first use and runs a headless session. The cache
  is refreshed automatically when the AppImage changes.

The bundled CLI owns the MCP surface (16 tools plus the `wordcraft://document`
and `wordcraft://commands` resources), so tool names and result shapes match
WordCraft 0.10.0. The launcher additionally applies the `list_commands` `query`
filter, which 0.10.0 accepts but ignores.

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `WORDCRAFT_PORT` | `7979` | Control-channel port |
| `WORDCRAFT_APPIMAGE` | `~/AppImages/wordcraft.appimage` | AppImage location |
| `WORDCRAFT_MODE` | auto | Force `direct` or `headless` |
| `WORDCRAFT_CLI` | extracted cache | Use an explicit `wordcraft-cli` binary |
| `WORDCRAFT_READ_ROOT` | `$HOME` | Headless read confinement |
| `WORDCRAFT_WRITE_ROOT` | `$HOME` | Headless write confinement |
| `WORDCRAFT_AUTHOR` | unset | Optional headless author name |

WordCraft and GridCraft both default to port `7979`. Both MCP servers probe the
listener and fall back to their headless engine when the port belongs to the
other app, so both tool sets stay usable; only the app that owns `7979` is
controlled live. To control both live, start WordCraft with `--control 7978` and
set `WORDCRAFT_PORT=7978` in the OpenCode service environment.

---

## 🔗 Related Modules

- [`zsh`](../zsh) — provides `~/.zshenv` (OpenCode background-subagent variables) and
  `~/.zshadditions` (the untracked shell environment used to export `EXA_API_KEY`).

---

## 🔧 9. Editor Schema Warnings (Neovim)

Some editors report that V2 fields such as `agents`, `media`, `compaction`,
`watcher`, or `tool_output` are "not allowed", or that `compaction.keep` /
`compaction.buffer` are unknown. This is a **false positive**, not a configuration error:

- The `$schema` points at <https://opencode.ai/config.json>, which still describes the
  **v1** configuration shape, so newer v2 fields are not in it yet.
- OpenCode itself (v2) accepts and uses all of them — verify with
  `opencode debug config`, which prints the loaded configuration with no warnings.

Leaving `$schema` in place keeps completion and validation for the fields that *are*
described, so this is only cosmetic noise in the editor.

---

## 📈 10. Usage Sidebar

The usage panel is a **standalone TUI-only plugin**, published on npm as
[`opencode-session-usage`](https://www.npmjs.com/package/opencode-session-usage);
its source and release process live in the
[GitHub repository](https://github.com/Chromiell/opencode-session-usage).
`cli.json` installs the published package:

```json
{
  "plugins": ["opencode-session-usage"]
}
```

`cli.json` is the correct place for a TUI-only plugin: OpenCode's `opencode.jsonc`
plugin list is for server plugins or packages that ship both parts. OpenCode
resolves and installs the package from npm on first load.

The panel shows a whole-session total (reported cost when available, catalog-price
fallback for subscriptions) plus the OpenCode Go/Console
rolling, weekly and monthly meters. Its options live in the tracked
`usage-sidebar.json` next to `cli.json`:

```json
{
  "refreshMs": 120000,
  "position": "top",
  "compact": false,
  "title": "Usage",
  "showEstimate": true,
  "showMeters": true,
  "showBars": true,
  "barWidth": 22,
  "showReset": true,
  "warnAt": 70,
  "criticalAt": 90
}
```

The file is watched and display changes apply immediately; `position` is read at
plugin load and needs `/reload`. `position: "top"` places the panel between the
built-in Context and MCP sections by claiming the built-in Limit slot (empty on
Go-only setups, replaced if Console budgets are in use). `position: "bottom"` uses
the footer, which only has room for one row before the prompt area, so it pairs
with `"compact": true`.

Go meters require an **OpenCode Console account connected through OAuth** (not just a
service-account API key), because the usage endpoint resolves the workspace from the
OAuth credential's `metadata.orgID`. See the project README for the full setup,
troubleshooting, cost and ToS notes.
