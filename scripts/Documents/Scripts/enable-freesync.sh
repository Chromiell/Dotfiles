#!/bin/bash
# xrandr only works in X11 sessions, not Wayland
[ "$XDG_SESSION_TYPE" = x11 ] || exit 0
sleep 15
xrandr --output eDP --set "TearFree" on
