# Startup tasks that must run before the rest of the interactive configuration.
if command -v fastfetch &>/dev/null && [[ -r ~/.config/fastfetch/fastfetch.jsonc ]]; then
    command fastfetch -c ~/.config/fastfetch/fastfetch.jsonc
fi

# Load Powerlevel10k's instant prompt when available. Keep this near the top so
# the prompt appears quickly; skip it inside tmux to avoid duplicate initialization.
if [[ -z "$TMUX" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

alias fastfetch="fastfetch -c ~/.config/fastfetch/fastfetch.jsonc"

# Provide harmless fallback widgets until the completion plugins define them.
if [[ -z ${widgets[menu - search]} ]]; then
    menu-search() { zle .menu-search 2>/dev/null || return 0; }
    zle -N menu-search
fi
if [[ -z ${widgets[recent - paths]} ]]; then
    recent-paths() { return 0; }
    zle -N recent-paths
fi

# Keep Znap from creating compiled .zwc files automatically.
zstyle ':znap:*' auto-compile no

