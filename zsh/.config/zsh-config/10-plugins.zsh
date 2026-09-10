# Install and initialize Znap, then load the configured Zsh plugins.

# Locate or install the Znap plugin manager.
typeset znap_dir="$HOME/.config/zsh-config/znap"

if [[ ! -r "$znap_dir/znap.zsh" ]]; then
    print "" # Separate the installation message from the shell prompt.
    print -n "Cloning Znap plugin manager... "
    git clone --depth 1 --quiet -- https://github.com/marlonrichert/zsh-snap.git "$znap_dir" >/dev/null 2>&1
    print "Done!"
fi

source "$znap_dir/znap.zsh"

typeset -a plugins=(
    marlonrichert/zsh-autocomplete
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-history-substring-search
    zdharma-continuum/fast-syntax-highlighting
    romkatv/powerlevel10k
)

# Load each plugin once. Znap fetches plugins that are not installed yet.
for plugin in "${plugins[@]}"; do
    znap source "$plugin"
done
# Znap and all configured plugins are now available.

# Load terminal capability names before using the $terminfo parameter.
zmodload zsh/terminfo

# Make the completion menu available on Tab and Shift-Tab.
bindkey '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

