---
name: desktop-use
description: "Control the local Linux desktop GUI (Wayland/niri) from the agent loop: screenshot the screen, locate UI, move/click the pointer with ydotool, send keys, and manage windows via niri. Use for driving GUI apps, games, or any non-browser desktop interaction."
metadata:
  {
    "openclaw":
      {
        "requires":
          { "bins": ["grim", "ydotool", "ydotoold", "niri", "magick", "jq"] },
      },
  }
---

# Desktop Use

Drive the real desktop — the same screen a human sees — when the target is
**neither** a web page (use `playwright-cli` / `browser-use` for browsers) nor a
CLI tool. Typical uses: launching and operating GUI apps, navigating a game
launcher, clicking a native dialog, or verifying that a window rendered.

This environment is **Wayland + niri** (scrollable tiling compositor) with
`grim` for screenshots and `ydotool` for input. Go through the helper script:
it encapsulates the two error-prone primitives (pointer movement and cursor
detection) so they never have to be re-derived inline.

## Helper

```sh
S=~/.config/opencode/skills/desktop-use/scripts/desktop-use
"$S" help        # full command list
```

| Command | Purpose |
| :--- | :--- |
| `info` | Session, output, tool availability, `ydotoold` status |
| `shot [file]` | Full-screen screenshot (default `/tmp/opencode/desktop/shot.png`); prints the path |
| `crop X Y W H [file]` | Region screenshot |
| `move X Y` | Move pointer to absolute `(X,Y)` (clamp + relative; measured 1:1) |
| `cursor [--around X Y] [--radius N]` | Detect the pointer; prints `X,Y WxH` (region-scoped diff) |
| `click [X Y] [--button left\|right\|middle] [--double]` | Optionally move, then click |
| `key NAME...` | Tap one or more keys |
| `keydown NAME` / `keyup NAME` | Hold / release a key (build chords) |
| `type TEXT` | Type a string |
| `windows` / `focused` | List windows / show the focused window (niri JSON) |
| `focus ID` / `close` | Focus a window by ID / close the focused window |

## Core workflow (closed loop)

1. **Observe** — `"$S" shot`, then read the PNG with the `read` tool. Crop or
   zoom with `magick` when detail is needed.
2. **Locate** the target in real output coordinates (mind the scaling note).
3. **Act** — `"$S" click X Y` (or `move`, `key`, `type`, …).
4. **Verify** — screenshot again and confirm the state changed. Never assume a
   click landed; always close the loop.

Example — launch a tile in a launcher:

```sh
S=~/.config/opencode/skills/desktop-use/scripts/desktop-use
"$S" shot /tmp/opencode/desktop/01.png     # read it; find the tile center, e.g. 1180,420
"$S" click 1180 420 --double               # double-click to launch
sleep 5
"$S" shot /tmp/opencode/desktop/02.png     # confirm the new window / splash
```

## Critical gotchas (do not relearn these)

- **Never use `ydotool mousemove --absolute`.** libinput pointer acceleration
  makes it overshoot badly. The helper's `move` clamps to the origin with a large
  *relative* move (`-100000`) and then applies the exact delta, measured 1:1.
  This assumes acceleration is disabled (DMS sets `accel-speed 0.0`); if moves
  land wrong, check the compositor's pointer settings first.
- **A click is `ydotool click 0xC0`.** `0x00` only *selects* the left button and
  does nothing. Buttons: left `0xC0`, right `0xC1`, middle `0xC2` (`0x40` = down,
  `0x80` = up). The helper uses these; remember them if calling `ydotool`
  directly.
- **grim `-g` takes slurp geometry** — `"X,Y WxH"` (comma + space), **not**
  `WxH+X+Y`. Also `-o` (output) and `-g` (region) are **mutually exclusive**.
- **Cursor detection is region-scoped.** `grim -c` (with cursor) minus `grim`
  (without) over the *whole* screen picks up animated content and returns a huge
  bogus box; a small crop around the expected spot gives a clean `13x20` cursor.
  Prefer trusting `move`, and use `cursor --around X Y` only to confirm.
- **Coordinates from a `read` screenshot are scaled.** The harness downscales
  images to 1600 px wide, so on a 1920 px output multiply displayed coordinates
  by `1920/1600 = 1.2`. Measure on the *displayed* image, then scale up. Every
  helper command takes **real** output coordinates.
- **Keyboard goes to the focused window.** niri has focus-follows-mouse
  *disabled*, so hovering does not focus. Pointer events still land on the
  surface under the cursor, but for keys run `"$S" focus <id>` first.
- **`read` is how you see.** It renders PNGs directly; no separate vision tool
  is needed for static screenshots.

## Windows (niri)

`niri` is a scrollable tiling WM; windows live in columns on a workspace.

```sh
"$S" windows          # id  focused  app_id  title
"$S" focused          # id  app_id  title
"$S" focus 9          # give a window keyboard focus
"$S" close            # gracefully close the focused window
```

To quit a fullscreen app cleanly, focus it and `"$S" close` (equivalent to
`niri msg action close-window`) rather than killing the process.

## Keyboard keys

`key` / `keydown` / `keyup` accept these names (or a raw Linux input keycode):
`esc enter space tab backspace delete home end pageup pagedown insert up down
left right leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta
rightmeta capslock`, `a`–`z`, `0`–`9`, `minus equal comma period slash semicolon
apostrophe leftbrace rightbrace backslash grave`, `f1`–`f12`.

```sh
"$S" key esc
"$S" key enter
"$S" keydown leftalt; "$S" key f4; "$S" keyup leftalt   # Alt+F4
"$S" type "hello world"
```

## Prerequisites

Debian packages: `grim`, `ydotool` (with the `ydotoold` daemon running),
`niri`, `imagemagick` (`magick`), `jq`. Check with `"$S" info`. Not present and
not required: `wtype`, `maim`, `xdg-desktop-portal`, `wmctrl`.

## Safety

- Screenshot before acting and again after — operate in a closed loop.
- Prefer `focus` to change keyboard focus; a click also acts on whatever is under
  the cursor and may trigger unintended UI.
- Do not click destructive controls (Quit, Delete, power) or type into a
  terminal unless the task explicitly calls for it.
- `close` may discard unsaved work in a GUI app; confirm intent first.
