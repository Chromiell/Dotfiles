#!/usr/bin/env bash

IS_FLOATING=false

# 1. Try checking via JSON (100% reliable if jq is installed)
if command -v jq >/dev/null 2>&1; then
    IS_FLOATING=$(niri msg --json focused-window 2>/dev/null | jq -r '.is_floating // false')
else
    # 2. Fallback check if jq isn't installed
    if niri msg windows 2>/dev/null | grep -i -B 5 -A 10 "Is focused: true" | grep -q -i "Is floating: true"; then
        IS_FLOATING=true
    fi
fi

# If floating, move it back to the tiling grid first
if [ "$IS_FLOATING" = "true" ]; then
    niri msg action toggle-window-floating
    sleep 0.05 # Critical pause for Niri layout engine to catch up
fi

# Maximize the column
niri msg action maximize-column
