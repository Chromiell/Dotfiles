#!/bin/bash
# Dependencies: tesseract-ocr tesseract-ocr-eng tesseract-ocr-ita imagemagick wl-clipboard libnotify-bin flameshot

LANGS="eng+ita"

# 1. Create a temp file for the screenshot
TMP_IMG=$(mktemp --suffix=.png)
trap 'rm -f "$TMP_IMG"' EXIT

# 2. Trigger Flameshot to capture a region and stream raw PNG bytes to the temp file
# (If Flameshot behaves oddly in Niri, prepend 'env XDG_CURRENT_DESKTOP=sway')
flameshot gui --raw >"$TMP_IMG" 2>/dev/null

# 3. If user presses ESC or cancels the selection, exit quietly
if [ ! -s "$TMP_IMG" ]; then
    exit 0
fi

# 4. Optimize image in-place for OCR (Grayscale + Up-scale)
mogrify -modulate 100,0 -resize 400% "$TMP_IMG"

# 5. Run tesseract and capture output
EXTRACTED_TEXT=$(tesseract "$TMP_IMG" - -l $LANGS 2>/dev/null)

# 6. Copy text to clipboard and notify if text was found
if [ -n "$EXTRACTED_TEXT" ]; then
    echo -n "$EXTRACTED_TEXT" | wl-copy
    notify-send --app-name "Text Grabber" --icon "edit-paste" "Text Extracted!" "The OCR text is now in your clipboard."
else
    notify-send --app-name "Text Grabber" --icon "dialog-warning" "No Text Found" "Tesseract couldn't detect any text in the selection."
fi
