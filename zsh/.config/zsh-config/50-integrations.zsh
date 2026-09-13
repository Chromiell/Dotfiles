# Optional integrations for completion, prompts, editors, and command-line tools.

# Load fzf keybindings and completion only when fzf is installed.
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# Initialize zoxide and replace the default cd completion when available.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init --cmd cd zsh)"
    if (($+functions[_z])); then
        compdef -d cd
        compdef _z cd
    fi
fi

# Load the local Powerlevel10k prompt configuration, if present.
[[ ! -f ~/.config/zsh-config/.p10k.zsh ]] || source ~/.config/zsh-config/.p10k.zsh

# Load VS Code's shell integration only inside a VS Code terminal.
if [[ "$TERM_PROGRAM" == "vscode" ]] && (( $+commands[code] )); then
    vscode_shell_integration="$(code --locate-shell-integration-path zsh 2>/dev/null)"
    [[ -r "$vscode_shell_integration" ]] && source "$vscode_shell_integration"
    unset vscode_shell_integration
fi

# Load NVM and its Bash completion helpers when configured.
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Add Cargo's tools to the environment when Rust is installed.
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Load optional machine-specific overrides without changing this module.
[[ ! -f ~/.zshadditions ]] || source ~/.zshadditions
