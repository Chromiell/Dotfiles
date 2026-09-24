---
name: playwright-cli
description: Drive a real browser from the terminal with the playwright-cli tool to open pages, inspect the DOM, click/fill forms, take screenshots, and verify frontend behaviour. Use for UI testing, visual verification, reproducing frontend bugs, and checking rendered output.
---

# Playwright CLI

`playwright-cli` is an installed CLI (the `@playwright/cli` npm package) that exposes
Playwright browser automation as simple terminal commands. Use it whenever a task
requires interacting with or verifying a real rendered web page.

## When to use

- Verify a frontend change actually renders and behaves correctly.
- Reproduce and debug a UI bug on a live/dev URL.
- Inspect the DOM, element refs, computed state, or take screenshots.
- Exercise forms, filters, modals, navigation, and responsive layouts.

## Who uses it

- `@designer` — UI implementation and visual verification (primary owner).
- `@fixer` — scripted functional/E2E checks and test suites.
- `@explorer` — read-only page/DOM reconnaissance.
- `@observer` — analyses the screenshots these agents capture.

The orchestrator must **delegate** browser work to one of the above; it may only
smoke-test that the tool exists.

## Session model

Each browser is a named session. Pass `-s=<session>` on every command to target a
specific session; without it the CLI uses the default session.

```sh
playwright-cli -s=verify goto https://example.test/page
```

Keep one session name per verification task so commands share the same browser
state. `open` starts a browser, `close` ends it, `attach`/`detach` reconnect.

## Core workflow

1. **Open / navigate**
   ```sh
   playwright-cli -s=verify open https://example.test/page
   # or, on an existing session:
   playwright-cli -s=verify goto https://example.test/page
   ```
2. **Snapshot to get element refs** — `snapshot` returns the page's elements with
   refs; `find` searches that snapshot for text/regexp and returns matching nodes.
   ```sh
   playwright-cli -s=verify snapshot
   playwright-cli -s=verify find "Accedi"
   ```
3. **Interact using refs from the snapshot**
   ```sh
   playwright-cli -s=verify click <ref>
   playwright-cli -s=verify fill <ref> "value"
   playwright-cli -s=verify select <ref> "option-value"
   playwright-cli -s=verify press Enter
   ```
4. **Verify the result** — snapshot again, or evaluate JS and screenshot.
   ```sh
   playwright-cli -s=verify snapshot
   playwright-cli -s=verify eval "() => document.querySelector('#result').textContent"
   playwright-cli -s=verify screenshot
   ```

## Command reference

**Sessions & navigation:** `open [url]`, `attach [name]`, `close`, `detach`,
`goto <url>`, `go-back`, `go-forward`, `reload`.

**Inspect:** `snapshot [target]`, `find [text]`, `eval <func> [target]`.

**Interact:** `click <target> [button]`, `dblclick <target>`, `fill <target> <text>`,
`type <text>`, `hover <target>`, `select <target> <val>`, `check <target>`,
`uncheck <target>`, `drag`, `drop`, `upload <files...>`.

**Keyboard:** `press <key>`, `keydown <key>`, `keyup <key>`.

**Mouse:** `mousemove <x> <y>`, `mousedown [button]`, `mouseup [button]`,
`mousewheel <dx> <dy>`.

**Dialogs:** `dialog-accept [prompt]`, `dialog-dismiss`.

**Viewport:** `resize <w> <h>`.

**Capture:** `screenshot [target]`, `pdf`.

**Tabs:** `tab-list`, `tab-new [url]`, `tab-close [index]`, `tab-select <index>`.

**Storage / state:** `state-load <filename>`, `state-save [filename]`,
`cookie-list`, `delete-data`.

## Tips

- Always `snapshot` (or `find`) before clicking — never guess element refs.
- Chain commands in one shell invocation when it saves round-trips, but keep the
  session name consistent.
- Pipe through `grep`/`sed` to trim large snapshots before they enter context.
- End the session with `close` when finished so browsers do not linger.
- If a page needs auth, use `state-load`/`state-save` to reuse a stored session.
