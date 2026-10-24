# GridCraft MCP

Self-contained MCP server for [GridCraft](https://gridcraft.ai) spreadsheets.
It replaces the old `~/.local/bin/gridcraft-mcp` and `~/.local/bin/gridcraft-cli`
shell wrappers. Only Node.js and the GridCraft AppImage are required.

## Backends

| Condition | Backend |
| :--- | :--- |
| GridCraft is listening on `127.0.0.1:7979` | Direct TCP control channel — operates on the live GUI workbook |
| Port is closed or belongs to another app | Headless — extracts `gridcraft-cli` from the AppImage to `~/.cache/gridcraft-mcp/` and runs its MCP engine |

WordCraft also defaults to port `7979`. Before bridging, the server checks that
the listener is GridCraft; if it is another app, it uses the headless engine.

Start GridCraft with its control channel enabled to use the live workbook:

```bash
~/AppImages/gridcraft.appimage --control 7979
```

The first headless run extracts the bundled CLI (about 13 MB). It is reused
until the AppImage's modification time changes.

## Configuration

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `GRIDCRAFT_PORT` | `7979` | Control-channel port |
| `GRIDCRAFT_APPIMAGE` | `~/AppImages/gridcraft.appimage` | AppImage location |
| `GRIDCRAFT_MODE` | auto | Force `direct` or `headless` |
| `GRIDCRAFT_TIMEOUT` | `120000` | Control-request timeout (ms) |

OpenCode launches it from `opencode.jsonc`:

```jsonc
"gridcraft": {
    "type": "local",
    "command": [
        "node",
        "{env:HOME}/.config/opencode/gridcraft-mcp/server.mjs",
    ],
},
```

## Tool schemas

`tools.json` mirrors the 21 tools exposed by the `gridcraft-cli` bundled in
GridCraft 0.11.1. The server maps each tool onto the control protocol
(`engine.execute`, `sheet.read`, `document.inspect`, `ui.screenshot`, and
`engine.commands`). When GridCraft updates, refresh the schemas from the new
bundle if the tool surface changes:

```bash
cd ~/.dotfiles/opencode/.config/opencode/gridcraft-mcp
CLI=~/.cache/gridcraft-mcp/gridcraft-cli

printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"schema-refresh","version":"1"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' |
  "$CLI" mcp 2>/dev/null |
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const m=s.trim().split("\n").map(JSON.parse).find(x=>x.id===2);process.stdout.write(JSON.stringify(m.result.tools,null,2)+"\n")})' \
  > tools.json
```

The direct backend intentionally mirrors the CLI's tool names, arguments, and
result shapes so agents see the same interface in both modes.
