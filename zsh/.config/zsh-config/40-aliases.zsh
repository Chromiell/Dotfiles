# Command shortcuts and terminal color settings.
# Make `history` display the complete history list.
alias history="history 0"

# Configure command colors and completion colors when dircolors is available.
if (( $+commands[dircolors] )); then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    export LS_COLORS="$LS_COLORS:ow=30;44:" # Keep world-writable directories easy to spot.

    alias ls='ls --color=auto' # Colorize listings when output is connected to a terminal.
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    # Reuse the terminal color palette for completion menus.
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# Use ripgrep to highlight colors
alias hl='rg --passthru --color=always'

# Use fastfetch with a custom config file.
alias fastfetch="fastfetch -c ~/.config/fastfetch/fastfetch.jsonc"

# Basic file and resource aliases.
alias cp="cp -i"     # Ask before overwriting a file.
alias df='df -h'     # Show disk sizes in a readable format.
alias free='free -m' # Show memory sizes in megabytes.

# File-listing helpers.
alias fd='fdfind'

# Enhanced eza listing aliases.
alias l='eza --group-directories-first --icons=auto'
alias la='eza -a --group-directories-first --icons=auto'
alias ll="eza -alhg --group-directories-first --icons=auto"
alias llt="eza -alhgT --group-directories-first --icons=auto"
alias lll="eza -alhg --group-directories-first --total-size --icons=auto"
alias lllt="eza -alhgT --group-directories-first --total-size --icons=auto"
alias ff="fzf \
  --style full --border --padding 1,2 \
  --border-label ' FuzzyFind ' \
  --input-label ' Input ' \
  --header-label ' File Type ' \
  --preview '~/.config/fzf/fzf-preview.sh {}' \
  --bind 'page-up:preview-half-page-up' \
  --bind 'page-down:preview-half-page-down' \
    $(if [[ "${_PAGER_PROG}" == "less" ]]; then printf "  --bind 'ctrl-f:execute(%s {})' \\" "${_PAGER_PROG}"; else printf "  --bind 'ctrl-p:execute(%s --paging=always {})' \\" "${_PAGER_PROG}"; fi)
  --bind 'ctrl-e:execute(micro {})' \
  --bind 'ctrl-n:execute(nvim {})' \
  --bind 'ctrl-v:execute(vim {})' \
  --bind 'result:transform-list-label: if [[ -z \$FZF_QUERY ]]; then echo \" \$FZF_MATCH_COUNT items \" else echo \" \$FZF_MATCH_COUNT matches for [\$FZF_QUERY] \" fi' \
  --bind 'focus:transform-preview-label:[[ -n {} ]] && printf \" Previewing [%s] \" {}' \
  --bind 'focus:+transform-header:file --brief {} || echo \"No file selected\"' \
  --bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
  --color 'border:#aaaaaa,label:#cccccc' \
  --color 'preview-border:#9999cc,preview-label:#ccccff' \
  --color 'list-border:#669966,list-label:#99cc99' \
  --color 'input-border:#996666,input-label:#ffcccc' \
  --color 'header-border:#6699cc,header-label:#99ccff'"
alias "cd.."="cd .."

# Tmux session and window shortcuts.
alias ta='tmux attach -t'
alias ts='tmux ls'
alias tk='tmux kill-session -t'
alias tkw='tmux kill-window -t'
alias tks='tmux kill-server'
alias tn='tmux new -n shell -s'
alias tnw='tmux new-window -n'
alias tdet='tmux detach'
alias tsplit='tmux split-window -v'
alias tvsplit='tmux split-window -h'
alias tkillp='tmux kill-pane'
alias tclean='tmux ls | grep -o "^[^:]*" | xargs -I{} tmux has-session -t {} 2>/dev/null || tmux kill-session -t {}'

# Start live-server with common development directories ignored.
alias live='live-server --ignorePattern="^(node_modules|vendor|\.git|.*\.(jpg|jpeg|png|gif|svg|webp|bmp|ico|tiff|tif|avif))$" --port=5500 --no-browser'

# Use batcat or bat if available
if whence -p batcat >/dev/null 2>&1; then
    alias bat="batcat --paging=never"
    alias batcatt="batcat --style=plain --paging=always"
    alias batcat="batcat --paging=always"
    alias batt="batcat -pp"
elif whence -p bat >/dev/null 2>&1; then
    alias bat="bat --paging=never"
    alias batcatt="bat --style=plain --paging=always"
    alias batcat="bat --paging=always"
    alias batt="bat -pp"
fi
