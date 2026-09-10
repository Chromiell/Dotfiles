# Load the numbered Zsh configuration modules in dependency order.
typeset zsh_config_root="${XDG_CONFIG_HOME:-$HOME/.config}/zsh-config"

for zsh_config_file in \
    00-startup.zsh \
    10-plugins.zsh \
    20-settings.zsh \
    30-functions.zsh \
    40-aliases.zsh \
    50-integrations.zsh; do
    [[ -r "$zsh_config_root/$zsh_config_file" ]] && source "$zsh_config_root/$zsh_config_file"
done

unset zsh_config_file zsh_config_root
