# WordCraft MCP

Self-contained MCP server for [WordCraft](https://getartcraft.com/apps/wordcraft)
documents. It needs only Node.js and the WordCraft AppImage; there are no helper
scripts in `~/.local/bin`.

The launcher extracts the `wordcraft-cli` bundled inside the AppImage and hands
the MCP protocol to it, so the tool surface is exactly the one shipped with
WordCraft 0.10.0: 16 tools plus the `wordcraft://document` and
`wordcraft://commands` resources. The only interception is the `list_commands`
`query` filter, which 0.10.0 accepts but does not apply.

## Backends

| Condition | Backend |
| :--- | :--- |
| WordCraft is listening on `127.0.0.1:7979` | Direct control channel — operates on the live GUI document |
| Port is closed or belongs to another app | Headless — extracts `wordcraft-cli` to `~/.cache/wordcraft-mcp/` and runs a headless session |

Start WordCraft with its control channel enabled to use the live document:

```bash
~/AppImages/wordcraft.appimage --control 7979
```

The first headless run extracts the bundled CLI (about 77 MB). It is reused
until the AppImage's modification time changes.

## Configuration

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `WORDCRAFT_PORT` | `7979` | Control-channel port |
| `WORDCRAFT_APPIMAGE` | `~/AppImages/wordcraft.appimage` | AppImage location |
| `WORDCRAFT_MODE` | auto | Force `direct` or `headless` |
| `WORDCRAFT_CLI` | extracted cache | Use an explicit `wordcraft-cli` binary |
| `WORDCRAFT_READ_ROOT` | `$HOME` | Headless read confinement |
| `WORDCRAFT_WRITE_ROOT` | `$HOME` | Headless write confinement |
| `WORDCRAFT_AUTHOR` | unset | Optional headless author name |

OpenCode launches it from `opencode.jsonc`. It is registered with
`"disabled": true`, so it stays unconnected until you remove that line (or
enable it in the client) and restart the service:

```jsonc
"wordcraft": {
    "type": "local",
    "disabled": true,
    "command": [
        "node",
        "{env:HOME}/.config/opencode/wordcraft-mcp/server.mjs",
    ],
},
```

WordCraft and GridCraft both default to port `7979`. The launcher probes the
listener and falls back to a headless session when the port belongs to the
other app, so both tool sets stay usable; only the app that owns `7979` is
controlled live. To control both live, start WordCraft with `--control 7978`
and set `WORDCRAFT_PORT=7978` in the OpenCode service environment.

## Cache

The extracted binary lives at `~/.cache/wordcraft-mcp/wordcraft-cli`. Delete it
to force a fresh extraction; the launcher also re-extracts automatically when
the AppImage is newer than the cache.
