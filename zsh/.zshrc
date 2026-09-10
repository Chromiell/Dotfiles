if command -v fastfetch &>/dev/null && [[ -r ~/.config/fastfetch/fastfetch.jsonc ]]; then
    command fastfetch -c ~/.config/fastfetch/fastfetch.jsonc
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# Enable instant prompt only if NOT in a tmux session
if [[ -z "$TMUX" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

alias fastfetch="fastfetch -c ~/.config/fastfetch/fastfetch.jsonc"

# create no-op widgets if they don't exist
if [[ -z ${widgets[menu - search]} ]]; then
    menu-search() { zle .menu-search 2>/dev/null || return 0; }
    zle -N menu-search
fi
if [[ -z ${widgets[recent - paths]} ]]; then
    recent-paths() { return 0; }
    zle -N recent-paths
fi

# Disable automatic compilation of .zwc files
zstyle ':znap:*' auto-compile no

# --- Plugin Manager Setup ---
local znap_dir="$HOME/.config/zsh-config/znap"
local plugins_dir="${znap_dir:h}" # Points to $HOME/.config/zsh-config

if [[ ! -r "$znap_dir/znap.zsh" ]]; then
    print "" # Newline before progress bar
    print -n "Cloning Znap plugin manager... "
    git clone --depth 1 --quiet -- https://github.com/marlonrichert/zsh-snap.git "$znap_dir" >/dev/null 2>&1
    print "Done!"
fi

source "$znap_dir/znap.zsh"

local -a plugins=(
    marlonrichert/zsh-autocomplete
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-history-substring-search
    zdharma-continuum/fast-syntax-highlighting
    romkatv/powerlevel10k
)

# Check if any plugins are missing from disk
local missing_plugins=0
for plugin in "${plugins[@]}"; do
    # Checks both author/repo and plain repo directory structures
    if [[ ! -d "$plugins_dir/$plugin" && ! -d "$plugins_dir/${plugin:t}" ]]; then
        missing_plugins=1
        break
    fi
done

# Show progress bar ONLY on initial plugin setup
if ((missing_plugins)) && command -v pv &>/dev/null; then
    print "" # Newline before progress bar
    {
        for plugin in "${plugins[@]}"; do
            znap source "$plugin" >/dev/null 2>&1
            echo "$plugin"
        done
    } | pv -l -s ${#plugins[@]} -p -t -e -N "Loading Plugins" >/dev/null
fi

# Finalize loading into current environment
for plugin in "${plugins[@]}"; do
    znap source "$plugin"
done
# - End Plugin Manager Setup -

bindkey '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

setopt autocd              # change directory just by typing its name
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt
setopt globdots            # lets files beginning with a . be matched without explicitly specifying the dot

WORDCHARS=${WORDCHARS//\//} # Don't consider certain characters part of the word

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# configure key keybindings
bindkey -e                                     # emacs key bindings
bindkey ' ' magic-space                        # do history expansion on space
bindkey '^U' backward-kill-line                # ctrl + U
bindkey '^[[3;5~' kill-word                    # ctrl + Supr
bindkey '^[[3~' delete-char                    # delete
bindkey '^[[1;5C' forward-word                 # ctrl + ->
bindkey '^[[1;5D' backward-word                # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history # page up
bindkey '^[[6~' end-of-buffer-or-history       # page down
bindkey '^[[H' beginning-of-line               # home
bindkey '^[[F' end-of-line                     # end
bindkey '^Z' undo                              # ctrl + z undo last action
bindkey '^Y' redo                              # ctrl + y redo last action
bindkey '^e' list-expand                       # ctrl + e check glob expansion

# History configurations
HISTFILE=~/.zhistory
HISTSIZE=10000
SAVEHIST=10000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi

unset color_prompt force_color_prompt

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
    export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# enable auto-suggestions based on the history
# change suggestion color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

## Options section
setopt correct # Auto correct mistakes
# setopt extendedglob       # Extended globbing. Allows using regular expressions with * -- Currently commented because it breaks nvm in v0.40.6
setopt nocaseglob         # Case insensitive globbing
setopt rcexpandparam      # Array expension with parameters
setopt nocheckjobs        # Don't warn about running processes when exiting
setopt nobeep             # No beep
setopt appendhistory      # Immediately append history instead of overwriting
setopt histignorealldups  # If a new command is a duplicate, remove the older one
setopt inc_append_history # save commands are added to the history immediately, otherwise only when shell exits.

WORDCHARS=${WORDCHARS//\/[&.;]/} # Don't consider certain characters part of the word

## Keybindings section
bindkey -e
bindkey '^[[7~' beginning-of-line # Home key
bindkey '^[[H' beginning-of-line  # Home key
if [[ "${terminfo[khome]}" != "" ]]; then
    bindkey "${terminfo[khome]}" beginning-of-line # [Home] - Go to beginning of line
fi
bindkey '^[[8~' end-of-line # End key
bindkey '^[[F' end-of-line  # End key
if [[ "${terminfo[kend]}" != "" ]]; then
    bindkey "${terminfo[kend]}" end-of-line # [End] - Go to end of line
fi
bindkey '^[[2~' overwrite-mode                    # Insert key
bindkey '^[[3~' delete-char                       # Delete key
bindkey '^[[C' forward-char                       # Right key
bindkey '^[[D' backward-char                      # Left key
bindkey '^[[5~' history-beginning-search-backward # Page up key
bindkey '^[[6~' history-beginning-search-forward  # Page down key

# Navigate words with ctrl+arrow keys
bindkey '^[Oc' forward-word     #
bindkey '^[Od' backward-word    #
bindkey '^[[1;5D' backward-word #
bindkey '^[[1;5C' forward-word  #
bindkey '^H' backward-kill-word # delete previous word with ctrl+backspace
bindkey '^[[Z' undo             # Shift+tab undo last action

## Alias section
alias cp="cp -i"     # Confirm before overwriting something
alias df='df -h'     # Human-readable sizes
alias free='free -m' # Show sizes in MB

# Theming section
autoload -U colors zcalc
colors

# Color man pages
export GROFF_NO_SGR=0
export MANROFFOPT='-c'
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-R

## Plugins section: Enable fish style features
# bind UP and DOWN arrow keys to history substring search
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Offer to install missing package if command is not found
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then
    source /usr/share/zsh/functions/command-not-found.zsh
    export PKGFILE_PROMPT_INSTALL_MISSING=1
fi

# Set terminal window and tab/icon title
function title {
    emulate -L zsh
    setopt prompt_subst

    [[ "$EMACS" == *term* ]] && return

    # if $2 is unset use $1 as default
    # if it is set and empty, leave it as is
    : ${2=$1}

    case "$TERM" in
        xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty | st*)
            print -Pn "\e]2;${2:q}\a" # set window name
            print -Pn "\e]1;${1:q}\a" # set tab name
            ;;
        screen* | tmux*)
            print -Pn "\ek${1:q}\e\\" # set screen hardstatus
            ;;
        *)
            # Try to use terminfo to set the title
            if [[ -n "$terminfo[fsl]" ]] && [[ -n "$terminfo[tsl]" ]]; then
                echoti tsl
                print -Pn "$1"
                echoti fsl
            fi
            ;;
    esac
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<" #15 char left truncated PWD
ZSH_THEME_TERM_TITLE_IDLE="%n@%m:%~"

autoload -U add-zsh-hook

# File and Dir colors for ls and other outputs
export LS_OPTIONS='--color=always'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias fd='fdfind'

# Detect external pager program (prefer external `batcat`, then `bat`, else `less`)
if whence -p batcat >/dev/null 2>&1; then
    _PAGER_PROG=batcat
elif whence -p bat >/dev/null 2>&1; then
    _PAGER_PROG=bat
else
    _PAGER_PROG=less
fi

# Custom functions
# Extracts any archive(s) (if unp isn't installed)
extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
                *.tar.bz2) tar xvjf $archive ;;
                *.tar.gz) tar xvzf $archive ;;
                *.tar.xz) tar xvJf $archive ;;
                *.bz2) bunzip2 $archive ;;
                *.rar) rar x $archive ;;
                *.gz) gunzip $archive ;;
                *.tar) tar xvf $archive ;;
                *.tbz2) tar xvjf $archive ;;
                *.tgz) tar xvzf $archive ;;
                *.zip) unzip $archive ;;
                *.Z) uncompress $archive ;;
                *.7z) 7z x $archive ;;
                *) echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# Searches for text in all files in the current folder
ftext() {
    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a _tmp_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ignore)
                NO_IGNORE_OPT="--no-ignore"
                shift
                ;;
            --no-color)
                COLOR_OPT="--color=never"
                shift
                ;;
            *)
                _tmp_args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${_tmp_args[@]}"

    if [[ -z "$1" ]]; then
        echo "Usage: ftext <pattern> [file]"
        return 1
    fi

    if [[ -n "$2" ]]; then
        if [[ ! -f "$2" ]]; then
            echo "File '$2' not found" >&2
            return 1
        fi

        case "${_PAGER_PROG}" in
            batcat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | batcat --style=plain || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | batcat --style=plain ;;
            bat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | bat --style=plain || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | bat --style=plain ;;
            *) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | less || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | less ;;
        esac
        return $?
    fi

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | batcat --style=plain || find . -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | batcat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | batcat --style=plain || find . -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | bat --style=plain || find . -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | bat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | bat --style=plain || find . -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | less || find . -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | less
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | less || find . -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Searches for text in all files in the current folder recursively
frtext() {
    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a _tmp_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ignore)
                NO_IGNORE_OPT="--no-ignore"
                shift
                ;;
            --no-color)
                COLOR_OPT="--color=never"
                shift
                ;;
            *)
                _tmp_args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${_tmp_args[@]}"

    case "${_PAGER_PROG}" in
        batcat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | batcat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" . | batcat --style=plain ;;
        bat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | bat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" . | bat --style=plain ;;
        *) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | less || grep -iIHRn ${COLOR_OPT} -- "$1" . | less ;;
    esac
}

# Searches for a specific filename only in the current directory
ffile() {
    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a _tmp_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ignore)
                NO_IGNORE_OPT="--no-ignore"
                shift
                ;;
            --no-color)
                COLOR_OPT="--color=never"
                shift
                ;;
            *)
                _tmp_args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${_tmp_args[@]}"

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -d 1 -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less || find . -maxdepth 1 -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Searches for a specific filename in the current directory and subdirectories
frfile() {
    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a _tmp_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ignore)
                NO_IGNORE_OPT="--no-ignore"
                shift
                ;;
            --no-color)
                COLOR_OPT="--color=never"
                shift
                ;;
            *)
                _tmp_args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${_tmp_args[@]}"

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain || find . -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain || find . -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain || find . -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain || find . -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less || find . -iname "*$1*" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less
            else
                command -v fd >/dev/null 2>&1 && fd --hidden -L -i "$1" ${NO_IGNORE_OPT} . 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less || find . -iname "*$1*" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Copy file with a progress bar
cpp() {
    rsync -avh --progress "$1" "$2"
}

# List Directories Types and icons
ld() {
    if (($#)); then eza -d --group-directories-first --icons=auto "$@"; else eza -D --group-directories-first --icons=auto; fi
}

# List All Directories Types and icons
lad() {
    if (($#)); then eza -ad --group-directories-first --icons=auto "$@"; else eza -aD --group-directories-first --icons=auto; fi
}

# Long Listing of Directories first Types and icons
lld() {
    if (($#)); then eza -alhgd --group-directories-first --icons=auto "$@"; else eza -alhgD --group-directories-first --icons=auto; fi
}

# Long Listing of Directories with their subdirectories, with Types and icons
lltd() {
    if (($#)); then eza -alhgTd --group-directories-first --icons=auto "$@"; else eza -alhgTD --group-directories-first --icons=auto; fi
}

# Long Listing of Directories, with total size and icons
llld() {
    if (($#)); then eza -alhgd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgD --group-directories-first --total-size --icons=auto; fi
}

# Long Listing of Directories with their subdirectories, with Types, total size and icons
llltd() {
    if (($#)); then eza -alhgTd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgTD --group-directories-first --total-size --icons=auto; fi
}

# Rewrite man command to use batcat instead of less
man() {
    case "${_PAGER_PROG}" in
        batcat) command man "$@" | col -bx | batcat --language=man --paging=always --style=plain ;;
        bat) command man "$@" | col -bx | bat --language=man --paging=always --style=plain ;;
        *) command man "$@" ;;
    esac
}

# Create a file of the appropriate size or a stream of random bytes
mktext() {
    local force=0 raw=0 printable=1 symbols=0 mkdirp=0 size_str="" outfile=""

    while [[ "$1" == -* ]]; do
        case "$1" in
            -f) force=1 ;;
            -r)
                raw=1
                printable=0
                ;;
            -s) symbols=1 ;;
            -p) mkdirp=1 ;;
            --)
                shift
                break
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: mktext [-f] [-r] [-p] <size> [<filename>]"
        return 1
    fi

    size_str="$1"
    if [[ $# -eq 2 ]]; then outfile="$2"; else outfile=""; fi

    if [[ ! "$size_str" =~ ^([0-9]+)([KkMmGgTt]|KiB|MiB|GiB|TiB)?$ ]]; then
        echo "Error: size must be like 100M, 1G, 50K, 500, 100MiB, 1GiB"
        return 1
    fi

    local num="${match[1]}" unit="${match[2]}" size_bytes
    case "$unit" in
        K | k | KiB) size_bytes=$((num * 1024)) ;;
        M | m | MiB) size_bytes=$((num * 1024 * 1024)) ;;
        G | g | GiB) size_bytes=$((num * 1024 * 1024 * 1024)) ;;
        T | t | TiB) size_bytes=$((num * 1024 * 1024 * 1024 * 1024)) ;;
        "") size_bytes=$num ;;
    esac

    if ((size_bytes == 0)); then
        if [[ -n "$outfile" ]]; then
            if [[ -e "$outfile" && $force -eq 0 ]]; then
                echo "Error: '$outfile' exists. Use -f to overwrite."
                return 1
            fi
            [[ $mkdirp -eq 1 ]] && mkdir -p -- "$(dirname -- "$outfile")"
            touch "$outfile"
            return 0
        else return 0; fi
    fi

    if [[ -n "$outfile" && -e "$outfile" && $force -eq 0 ]]; then
        echo "Error: '$outfile' exists. Use -f to overwrite."
        return 1
    fi

    if [[ -n "$outfile" && $mkdirp -eq 1 ]]; then
        mkdir -p -- "$(dirname -- "$outfile")"
    fi

    local cmd
    if ((raw == 1)); then
        cmd="cat /dev/urandom"
    elif ((symbols == 1)); then
        cmd="tr -dc '[:alnum:]!@#$%^&*' < /dev/urandom"
    else cmd="tr -dc '[:alnum:]' < /dev/urandom"; fi

    local start_time=$SECONDS
    if [[ -n "$outfile" ]]; then
        echo "Creating file '$outfile' (${size_bytes} bytes)..."
        if command -v pv >/dev/null 2>&1; then
            eval "$cmd" | pv -s "$size_bytes" | head -c "$size_bytes" >"$outfile"
        else eval "$cmd" | head -c "$size_bytes" >"$outfile"; fi
    else
        eval "$cmd" | head -c "$size_bytes"
    fi

    local elapsed=$((SECONDS - start_time))
    if [[ -n "$outfile" ]]; then echo "Done in ${elapsed}s"; else printf '\nDone in %ss\n' "${elapsed}" >&2; fi
}

# Create a new tmux session with a random name
t() {
    local adjs animals a n session

    adjs=(
        brave bold calm clever swift silent noble fierce gentle mighty rapid wild
        bright sharp steady agile fearless loyal proud wise keen lively quiet strong
        daring epic mystic radiant rugged sturdy vivid eager fiery frosty stormy sunny
        shadowy crimson golden silver iron stone velvet cosmic lunar solar arcane prime
    )

    animals=(
        wolf falcon tiger panther eagle bear lynx fox owl hawk dolphin whale shark
        octopus seal otter badger bison buffalo moose deer antelope gazelle cheetah
        leopard jaguar rhino hippo crocodile alligator tortoise lizard python cobra
        sparrow raven crow parrot penguin koala kangaroo camel horse donkey boar rabbit
        squirrel hedgehog goose swan
    )

    # Loop until we find a free name
    while true; do
        a=${adjs[$((RANDOM % ${#adjs[@]} + 1))]}
        n=${animals[$((RANDOM % ${#animals[@]} + 1))]}
        session="${a}_${n}"

        # Check if session exists
        if ! tmux has-session -t "$session" 2>/dev/null; then
            break
        fi
    done

    tmux new-session -s "$session" -n shell
}

# Attach to an existing tmux session or create a new one if it doesn't exist
taa() {
    local name="$1"
    [ -z "$name" ] && name="main"
    tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" || tmux new -n shell -s "$name"
}

# Start a detached tmux session that runs a command and logs output to a file
tbg() {
    local name="$1"
    shift
    local logfile="$HOME/tmux-logs/${name}.log"
    mkdir -p "$HOME/tmux-logs"
    tmux new-session -d -s "$name" "{ echo \"[Started at: \$(date)]\"; $@ 2>&1; echo \"[Finished at: \$(date)]\"; } | tee -a \"$logfile\""
    echo -e "Started detached tmux job '$name'\nLogging to: $logfile"
}

# Attach to a tmux session selected via fzf
tsp() {
    local session
    session=$(tmux ls -F '#S' | fzf) || return
    tmux attach -t "$session"
}

# Attach to the most recently used tmux session (excluding the current one)
tlast() {
    if [ -n "$TMUX" ]; then tmux switch-client -l 2>/dev/null && return; fi
    local session=$(tmux ls -F "#{session_created} #{session_name}" 2>/dev/null | sort -nr | awk 'NR==1 {print $2}')
    if [ -n "$session" ]; then tmux attach -t "$session"; else echo "No tmux sessions found"; fi
}

# Create a new tmux session with logging enabled for all panes
tnl() {
    local name="$1" logfile="$HOME/tmux-logs/${name}.log"
    if [ -z "$name" ]; then
        echo "Usage: tnl <session-name>"
        return 1
    fi
    mkdir -p "$HOME/tmux-logs"
    tmux new-session -d -s "$name"
    tmux pipe-pane -o -t "$name" "cat >> \"$logfile\""
    echo "Logging to: $logfile"
    tmux attach -t "$name"
}

# Completion function for tmux session names
_tp_sessions() {
    local -a sessions
    sessions=("${(@f)$(tmux ls -F '#S' 2>/dev/null)}")
    _describe 'tmux sessions' sessions
}

# Capture the output of a tmux pane and show the last N lines
tp() {
    local lines="$1" session="$2"
    if [ -z "$lines" ] || [ -z "$session" ]; then
        echo "Usage: tp <num-lines> <session-name>"
        return 1
    fi
    tmux capture-pane -p -t "$session" | tail -n "$lines"
}

# Alias for Yazi to be able to change directory by navigating the Yazi interface
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

vardump() {
    emulate -L zsh

    # read arguments
    local _vd_verbose=false
    local _vd_whencolor='auto'
    local _vd_show_help=false
    local OPTIND OPTARG opt

    while getopts 'C:vh-:' opt; do
        case "$opt" in
            C) _vd_whencolor=$OPTARG ;;
            v) _vd_verbose=true ;;
            h) _vd_show_help=true ;;
            -)
                case "$OPTARG" in
                    help) _vd_show_help=true ;;
                    *)
                        echo "vardump: unrecognized option '--$OPTARG'" >&2
                        return 1
                        ;;
                esac
                ;;
            *) return 1 ;;
        esac
    done
    shift "$((OPTIND - 1))"

    # display help message
    if [[ $_vd_show_help == true ]]; then
        echo "Usage: vardump [-v] [-C when] <variable_name>"
        echo "       vardump -h | --help"
        echo
        echo "Inspect and format the contents and attributes of a Zsh variable."
        echo
        echo "Options:"
        echo "  -v           Verbose output (displays attributes, header/footer, and length)."
        echo "  -C WHEN      Colorize output: 'always', 'never', or 'auto' (default: auto)."
        echo "  -h, --help   Display this help message."
        return 0
    fi

    # read target variable name
    local _vd_target=$1

    if [[ -z $_vd_target ]]; then
        echo 'vardump: name required as first argument' >&2
        echo 'Try "vardump --help" for more information.' >&2
        return 1
    fi

    # ensure the variable is defined
    if ! typeset -p "$_vd_target" &>/dev/null; then
        echo "variable ${(q+)_vd_target} not defined" >&2
        return 1
    fi

    # optionally load colors
    local color_green='' color_magenta='' color_rst='' color_dim=''
    if [[ $_vd_whencolor == always ]] || [[ $_vd_whencolor == auto && -t 1 ]]; then
        color_green=$'\e[32m'
        color_magenta=$'\e[35m'
        color_rst=$'\e[0m'
        color_dim=$'\e[2m'
    fi
    local color_value=$color_green
    local color_key=$color_magenta
    local color_length=$color_magenta

    # optionally print header
    if $_vd_verbose; then
        echo "${color_dim}--------------------------${color_rst}"
        echo "${color_dim}vardump: ${color_rst}$_vd_target"
    fi

    # get type attributes directly via Zsh parameter flags
    local _vd_raw_type="${(Pt)_vd_target}"
    local -a _vd_attrs=(${(s:-:)_vd_raw_type})
    local -a _vd_attributes=()
    local _vd_typ=''

    local _vd_attr
    for _vd_attr in "${_vd_attrs[@]}"; do
        case "$_vd_attr" in
            array)
                _vd_attributes+=("(a)indexed array")
                _vd_typ='a'
                ;;
            association)
                _vd_attributes+=("(A)associative array")
                _vd_typ='A'
                ;;
            scalar) _vd_attributes+=("(s)scalar") ;;
            integer) _vd_attributes+=("(i)integer") ;;
            float) _vd_attributes+=("(f)float") ;;
            readonly) _vd_attributes+=("(r)read-only") ;;
            export*) _vd_attributes+=("(x)exported") ;;
            local) _vd_attributes+=("(g)local") ;;
            *) _vd_attributes+=("($_vd_attr)") ;;
        esac
    done

    # optionally print attributes
    if $_vd_verbose; then
        echo -n "${color_dim}attributes: ${color_rst}"
        if ((${#_vd_attributes} > 0)); then
            echo "${(j:/:)_vd_attributes}"
        else
            echo '(none)'
        fi
    fi

    # print the variable value
    if [[ $_vd_typ == 'a' ]]; then
        local -a _vd_ref_a=("${(@P)_vd_target}")
        if $_vd_verbose; then
            printf '%s %s\n' \
                "${color_dim}length:${color_rst}" \
                "${color_length}${#_vd_ref_a}${color_rst}"
        fi
        echo '('
        local _vd_i
        for ((_vd_i = 1; _vd_i <= ${#_vd_ref_a}; _vd_i++)); do
            printf '\t[%s]=%s\n' \
                "${color_key}${_vd_i}${color_rst}" \
                "${color_value}${(q+)_vd_ref_a[_vd_i]}${color_rst}"
        done
        echo ')'
    elif [[ $_vd_typ == 'A' ]]; then
        local -A _vd_ref_A=("${(@Pkv)_vd_target}")
        if $_vd_verbose; then
            printf '%s %s\n' \
                "${color_dim}length:${color_rst}" \
                "${color_length}${#_vd_ref_A}${color_rst}"
        fi
        echo '('
        local _vd_k
        for _vd_k in "${(k)_vd_ref_A[@]}"; do
            printf '\t[%s]=%s\n' \
                "${color_key}${(q+)_vd_k}${color_rst}" \
                "${color_value}${(q+)_vd_ref_A[$_vd_k]}${color_rst}"
        done
        echo ')'
    else
        local _vd_val="${(P)_vd_target}"
        echo "${color_value}${(q+)_vd_val}${color_rst}"
    fi

    if $_vd_verbose; then
        echo "${color_dim}--------------------------${color_rst}"
    fi

    return 0
}

# Tell zsh how to complete arguments for tp
compdef '_arguments "1: : " "2:tmux session:_tp_sessions"' tp

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Load zoxide, then enforce completions
eval "$(zoxide init --cmd cd zsh)"
if (($+functions[_z])); then
    compdef -d cd
    compdef _z cd
fi

# ----------------------------------------------------

# some more ls aliases
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

# TMux aliases
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

# live-server alias
alias live='live-server --ignorePattern="^(node_modules|vendor|\.git|.*\.(jpg|jpeg|png|gif|svg|webp|bmp|ico|tiff|tif|avif))$" --port=5500 --no-browser'

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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh-config/.p10k.zsh.
[[ ! -f ~/.config/zsh-config/.p10k.zsh ]] || source ~/.config/zsh-config/.p10k.zsh

# Required by VSCode's agents terminal integration with Zsh
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# Load NVM safely
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Load cargo env
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Load any additional configuration options for the specific user
[[ ! -f ~/.zshadditions ]] || source ~/.zshadditions
