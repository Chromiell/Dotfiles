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
sudo apt install eza fzf bat fastfetch rsync micro rar gzip tar unzip 7zip bzip2 fd-find ripgrep pv vim zoxide jc jq
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
    - Producers: `psq` (processes), `lsq [-h] [path]` (directory listing like `ls -lA`, built from `find -printf` so filenames with spaces/newlines and full ISO dates survive; `-h` humanizes sizes to K/M/G), `dfq` (filesystems, exact byte sizes), `duq [-d <depth> | -a] [path]` (disk usage, one level deep by default like Nushell's `du`; `-a` walks the whole tree), `freeq` (memory), `ssq [-a]` (TCP/UDP sockets with numeric ports and owning process; `-a` adds Unix sockets), `journalq [--sudo] [journalctl args...]` (systemd journal → JSON with local-time `ts`; extra args pass through verbatim, e.g. `-r`, `-u nginx.service`, `--since -1h`), `jcq <command> [args...]` (any of jc's ~150 parsers via jc "magic" syntax, e.g. `jcq lsblk`, `jcq mount`; single-object results are wrapped in an array), `sep [sep] <field>...` (any delimiter → JSON; with a single argument each whole line becomes that field value; splitting stops once every field has a value, so a separator inside the last field is kept there; separator accepts printf `%b` escapes incl. hex bytes like `\x1f` — pair with `xxd` to find raw separators — or plain substrings; ANSI escape codes are stripped and CRLF endings handled; leading-zero values like `0755` stay strings; field-name prefixes `^name` split the follow fields from the right end, e.g. `sep ':' '^path line snippet'` when the path itself contains colons, and `name*` marks the default remainder behavior explicitly; `sep --help` documents all caveats), `csvq [-d <char>] [file]` (RFC 4180 CSV/TSV file or stdin → JSON records; `-d` takes a char, a printf escape like `'\t'`, or `tab`; handles quoted commas, doubled quotes, multi-line cells, and Excel BOMs; numbers and `true`/`false` are typed and empty cells become null; needs `python3`, which Debian preinstalls). Producers call their tools via `command` under `LC_ALL=C`, so aliases (`df='df -h'`) and non-English locales cannot break parsing.
    - Filter/reshape verbs: `where [--or] <field> <op> <value> [...]` (`> >= < <= == !=` numeric; `eq ne` equality; `contains not-contains` case-insensitive substring; `starts-with ends-with`; `matches '!~'` regex; `in not-in` comma-separated lists; `after before` lexicographic — correct for ISO-8601 timestamps like `journalq`'s `ts`; triples are AND-combined by default, `--or` keeps records matching any triple), `sel <field>...`, `reject <field>...`, `rename-col <old> <new> [...]`, `update <field> <jq-expr>` (`.` is the old value, `$row` the whole record; also adds new fields), `flatten` (nested records → dotted columns), `unnest [--keep] <field>` (a list/record field becomes its own table, one row per item, e.g. `jcq id | unnest groups | pretty`; `--keep` carries the parent columns, e.g. `ip -j addr | unnest --keep addr_info | sel ifname local prefixlen`), `transpose`.
    - Row verbs: `sort-by <field> [asc|desc] [<field> [asc|desc] ...]` (stable, multi-key), `first [n]`, `last [n]`, `skip [n]`, `reverse`, `row <n> | <start>:<end> | <n> <n> ...` (one-based, negative = from end, e.g. `row 5`, `row 5:10`, `row -1`), `uniq-by [field...]`.
    - Aggregation and output: `count`, `get <field>`, `group-by <field>` (`{field, count, items}` per value), `histogram <field>` (`{field, count, percent}`, most frequent first), `math sum|avg|min|max|median [field]`, `csv` (records → RFC 4180 CSV with a union-of-keys header row; round-trips types through `csvq` back into the verb pipeline), `pretty [--full] [--no-index] [--color <when>]` (Nushell-style bordered table: `#` row-number column matching `row`, bold-cyan header, magenta numbers, right-aligned numeric columns, widths measured in terminal cells so CJK/emoji align, columns truncated to terminal width, footer header only when the table is taller than the screen, a single record renders as a column/value table, ripgrep-style `--color never|auto|always|ansi` (also `--color=<when>`; `auto`, the default, colors only on a terminal without `NO_COLOR`, `always` keeps colors through pipes, e.g. `pretty --color always | less -R`); `--full` renders untruncated).
    - Field arguments accept dotted paths into nested records (`where o.b '>' 1`, `sel a.b`). Verbs also accept a single record instead of an array, and fail fast with a hint when nothing is piped in.
    - Example: `psq | where mem_percent '>' 1 | sel pid mem_percent command | sort-by mem_percent desc | first 5 | pretty`; journal workflow: `journalq --sudo -b -1 | where prio '<=' 4 | sort-by ts desc | first 10 | pretty` (errors/warnings from the previous boot, newest first); `journalq | histogram id | first 10 | pretty` (noisiest log sources).
    - Verb naming caveats: `sort-by`/`uniq-by` (not `sort`/`uniq`) avoid shadowing coreutils, `unnest` (not `expand`) avoids shadowing coreutils `expand`, `sel` replaces `select` because `select` is a reserved Zsh word, and `rename-col` avoids shadowing the Perl `rename` tool. `where` shadows the Zsh builtin of the same name and `last` shadows `/usr/bin/last` (login history); both fall back to the original when nothing is piped in. Every producer and verb accepts `--help`, and `lsq -h` humanizes file sizes to K/M/G.
    - Requires `jc` and `jq` (see Recommended CLI Tools). The `jc` Zsh completion (`_jc`) is generated automatically into `~/.local/share/zsh/site-functions` on first launch and registered on fpath before zsh-autocomplete runs its completion scan; `jcq` completes its arguments like a fresh command line.
- **CSV Round-Trip:** `csv` exports records to RFC 4180 CSV and `csvq` imports CSV files back into the verb pipeline (`sep ... | sel ... | csv > data.csv`, `csvq data.csv | where qty '>' 2 | pretty`) — no external table tools needed.
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
