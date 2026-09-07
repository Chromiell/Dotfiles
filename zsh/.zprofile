# 1. Tell Zsh to never allow duplicate entries in your PATH
typeset -U path

# 2. Add System Games (No longer tied to Wayland, no risky string matching)
[[ -d "/usr/local/games" ]] && path=(/usr/local/games $path)
[[ -d "/usr/games" ]] && path=(/usr/games $path)

# 3. Add Composer vendor binaries (Appended to the END of PATH)
[[ -d "$HOME/.config/composer/vendor/bin" ]] && path=($path "$HOME/.config/composer/vendor/bin")

# 4. Add Local binaries (Prepended to the FRONT of PATH)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# 5. Global Environment Variables
export QT_QPA_PLATFORMTHEME=gtk3
export NVM_DIR="$HOME/.config/nvm"
