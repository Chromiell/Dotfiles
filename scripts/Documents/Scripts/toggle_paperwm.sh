#!/bin/bash

EXTENSION_UUID="paperwm@paperwm.github.com"

# Check if the extension is enabled
STATUS=$(gnome-extensions info "$EXTENSION_UUID" | grep "State:" | awk '{print $2}')

if [ "$STATUS" == "ACTIVE" ]; then
    notify-send "PaperWM" "Disabling PaperWM..."
    gnome-extensions disable "$EXTENSION_UUID"
else
    notify-send "PaperWM" "Enabling PaperWM..."
    gnome-extensions enable "$EXTENSION_UUID"
fi
