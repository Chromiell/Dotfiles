# Zsh Configuration

A rich, responsive, and modern Zsh configuration optimized for Debian-based systems featuring **Znap** plugin management, the **Powerlevel10k** prompt theme, autosuggestions (via **Deja**), substring search, syntax highlighting, and custom aliases.

---

## 📦 1. Required Packages

### Required Core Packages
To use this Zsh configuration (including the Znap plugin manager):

```bash
sudo apt update
sudo apt install zsh git curl
```

> [!NOTE]
> The **Deja** autosuggestion engine is not packaged for Debian. `10-plugins.zsh`
> automatically downloads the latest release binary to `~/.local/bin/deja`
> (checksum-verified) on first launch, imports the zsh history, and generates its
> integration script. This requires `curl`, `tar`, and `sha256sum` (all standard). Deja's Tab
> rebinding is disabled in favor of the config's completion bindings; suggestion cycling
> lives on **Ctrl+N**. Running `znap pull` also reports whether a newer Deja release is
> available (delete `~/.local/bin/deja` and restart zsh to apply it).

### Recommended CLI Tools & Enhancements
For the complete terminal experience with all aliases, fast fetching, directory jumping, and enhanced previews:

```bash
sudo apt install eza fzf bat fastfetch rsync micro rar gzip tar unzip 7zip bzip2 fd-find ripgrep pv vim zoxide jc jq miller csvkit
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
| [`scripts`](../scripts) | Assets / Rendering | Powerlevel10k (`.p10k.zsh`) and CLI icons require the **Adwaita Mono Nerd Font** installed by `install-adwaita-nerd-font` for glyph rendering. |


### 🔑 Secrets & Environment Variables

Sensitive values are kept out of this repository. `50-integrations.zsh` sources
`~/.zshadditions` when it exists:

```bash
[[ ! -f ~/.zshadditions ]] || source ~/.zshadditions
```

`~/.zshadditions` is **not** tracked by this repository. Export API keys there so
other modules can consume them through environment substitution:

| Variable | Used by | Purpose |
| :--- | :--- | :--- |
| `CODESTRAL_API_KEY` | [`neovim`](../neovim) | Mistral **Codestral** provider for inline AI suggestions (`minuet-ai.nvim`, `codestral-latest`). |
| `GEMINI_API_KEY` | [`neovim`](../neovim) | Google **Gemini** provider for inline AI suggestions (`minuet-ai.nvim`, `gemini-3.5-flash-lite`) and CodeCompanion chat (`gemini-3.6-flash`). |
| `EXA_API_KEY` | [`opencode`](../opencode) | Exa web search MCP server, referenced as `{env:EXA_API_KEY}` in `opencode.jsonc`. |

The Neovim plugins read these variables by name in
`lua/plugins/inline-suggestions.lua` (`api_key = "CODESTRAL_API_KEY"` /
`"GEMINI_API_KEY"`) and `lua/plugins/codecompanion.lua`.

Example:

```bash
export CODESTRAL_API_KEY="your-codestral-key"
export GEMINI_API_KEY="your-gemini-key"
export EXA_API_KEY="your-exa-key"
```

> [!NOTE]
> After editing `~/.zshadditions`, open a new shell (or `source ~/.zshadditions`)
> so new sessions inherit the values. Restart OpenCode's background service
> (`opencode service restart`) and open a fresh Neovim instance for the plugins to
> pick up the keys.

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
- `~/.config/zsh/.p10k.zsh` $\rightarrow$ `~/.dotfiles/zsh/.config/zsh/.p10k.zsh`

## 🧱 3. Configuration Structure

`.zshrc` is intentionally kept as a small loader. It sources the numbered files in
`~/.config/zsh/` in order, so dependencies are initialized before the
configuration that uses them:

```text
~/.zshrc
└── ~/.config/zsh/
    ├── 00-startup.zsh         # Fastfetch, instant prompt, fallback widgets
    ├── 10-plugins.zsh         # Znap and Zsh plugins (Deja autosuggestions)
    ├── 20-settings.zsh        # Options, history, prompt, keybindings, colors
    ├── 30-functions.zsh       # Custom functions, structured-data verbs, jc completion setup
    ├── 40-aliases.zsh         # Command, eza, tmux, and utility aliases
    ├── 50-integrations.zsh    # fzf, zoxide, bat, VS Code, NVM, and Cargo
    └── .p10k.zsh              # Powerlevel10k prompt configuration
```

The numeric prefixes define the load order. Add general shell behavior to
`20-settings.zsh`, reusable shell functions to `30-functions.zsh`, aliases to
`40-aliases.zsh`, and external tool initialization to `50-integrations.zsh`.
Keep `.p10k.zsh` focused on Powerlevel10k prompt customization.

---

## 🐚 4. Change Default Shell to Zsh

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

## ✨ 5. Features & Included Plugins

- **Znap Plugin Manager:** Automatically clones and manages lightweight Zsh plugins upon first launch without manual setup.
- **Powerlevel10k Prompt:** Ultra-fast, highly informative prompt with instant prompt loading and custom theme settings (`.p10k.zsh`).
- **Autocompletion & Autosuggestions:** Interactive menu completion (`zsh-autocomplete`) and predictive ghost-text suggestions via **[Deja](https://github.com/Giammarco-Ferranti/deja)** — a Go daemon-style engine with fuzzy matching, directory awareness, and frecency scoring. Installed and initialized automatically on first shell launch (a drop-in replacement for the old `zsh-autosuggestions` plugin).
- **Nushell-Style Structured Data:** Nushell-like pipeline verbs over `jc` + `jq`, without leaving Zsh. Producer functions convert everyday command output into JSON records, then chainable verbs filter, project, and sort them:
    - Producers: `psq` (processes), `lsq` (directory listing), `dfq` (filesystems), `duq <path>` (directory sizes), `freeq` (memory), `ssq` (sockets), `journalq [--sudo] [journalctl args...]` (systemd journal → JSON; extra args pass through verbatim, e.g. `-r`, `-u nginx.service`, `--since -1h`), `sep [sep] <field>...` (any delimiter → JSON; with a single argument each whole line becomes that field value; separator accepts printf `%b` escapes incl. hex bytes like `\x1f` — pair with `xxd` to find raw separators — or plain substrings; ANSI escape codes are stripped from values; field-name prefixes `^name` split the follow fields from the right end, e.g. `sep ':' '^path line snippet'` when the path itself contains colons, and `name*` keeps the whole remaining line, e.g. `sep ':' file line '*snippet'`; `sep --help` documents all caveats).
    - Verbs: `where [--or] <field> <op> <value> [<field> <op> <value> ...]` (`> >= < <= == !=` numeric; `eq ne contains matches` string; `after before` lexicographic — correct for ISO-8601 UTC timestamps like `journalq`'s `ts`; triples are AND-combined by default, `--or` keeps records matching any triple), `sort-by <field> [asc|desc]`, `sel <field>...`, `first <n>`, `row <n> | <start>:<end> | <n> <n> ...` (one-based, negative = from end, e.g. `row 5`, `row 5:10`, `row -1`), `count`, `get <field>`, `pretty` (Nushell-style bordered table: bold-cyan header, magenta numbers, right-aligned numeric columns, and columns truncated to terminal width; `pretty --full` renders untruncated).
    - Example: `psq | where mem_percent '>' 1 | sel pid mem_percent command | sort-by mem_percent desc | first 5 | pretty`; journal workflow: `journalq --sudo -b -1 | where prio '<=' 4 | sort-by ts desc | first 10 | pretty` (errors/warnings from the previous boot, newest first).
    - Verb naming caveats: `sort-by` (not `sort`) avoids shadowing `/usr/bin/sort`, `sel` replaces `select` because `select` is a reserved Zsh word, and `where` shadows the rarely used Zsh builtin of the same name. Every producer and verb accepts `--help`, and `lsq -h` humanizes file sizes to K/M/G.
    - Requires `jc` and `jq` (see Recommended CLI Tools). The `jc` Zsh completion (`_jc`) is generated automatically into `~/.local/share/zsh/site-functions` on first launch and registered on fpath before zsh-autocomplete runs its completion scan.
- **Table Tools:** `miller` (`mlr`) provides name-indexed filter/sort/cut verbs over CSV/TSV/JSON, and `csvkit` offers SQL over CSV (`csvsql`, `csvcut`, `csvgrep`) — useful complements to the structured-data verbs for file-based data.
- **Syntax Highlighting:** Real-time command syntax highlighting (`fast-syntax-highlighting`).
- **History Substring Search:** Interactive substring search through command history using arrow keys.
- **vim History Cleanup:** `vimhistory` opens `$HISTFILE` with vim (falling back to micro or nano), then — after saving changes — recreates the Deja suggestion database from scratch (`_deja_rebuild`: wipes `deja.db`/`-wal`/`-shm`, re-imports the history file, and restarts the suggestion daemon detached).
- **Productivity Enhancements:** Integrated `zoxide` directory jumping, `eza` aliases, `fastfetch` system info display, and extensive utility aliases.

---

## 🪟 6. Windows Terminal Configuration (Nerd Fonts)

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
