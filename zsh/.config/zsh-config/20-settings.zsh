# Core interactive-shell behavior: options, history, prompt, keybindings, and colors.
# These settings apply to interactive Zsh sessions.

# Basic shell behavior.
setopt autocd              # change directory just by typing its name
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt
setopt globdots            # lets files beginning with a . be matched without explicitly specifying the dot

# Hide the end-of-line marker that Zsh shows when a command wraps.
PROMPT_EOL_MARK=""

# Use Emacs-style editing and define the most common editing shortcuts.
bindkey -e                                     # Use Emacs-style keybindings.
bindkey ' ' magic-space                        # Expand history expressions when Space is pressed.
bindkey '^U' backward-kill-line                # Ctrl+U deletes back to the start of the line.
bindkey '^[[3;5~' kill-word                    # Ctrl+Delete removes the next word.
bindkey '^[[3~' delete-char                    # Delete the character under the cursor.
bindkey '^[[1;5C' forward-word                 # Ctrl+Right moves forward one word.
bindkey '^[[1;5D' backward-word                # Ctrl+Left moves backward one word.
bindkey '^[[5~' beginning-of-buffer-or-history # Page Up searches backward through history.
bindkey '^[[6~' end-of-buffer-or-history       # Page Down searches forward through history.
bindkey '^[[H' beginning-of-line               # Home moves to the start of the line.
bindkey '^[[F' end-of-line                     # End moves to the end of the line.
bindkey '^Z' undo                              # Ctrl+Z undoes the last edit.
bindkey '^Y' redo                              # Ctrl+Y redoes the last edit.
bindkey '^e' list-expand                       # Ctrl+E previews glob expansion.

# History file and retention settings.
HISTFILE=~/.zhistory
HISTSIZE=10000
SAVEHIST=10000
setopt hist_expire_dups_first # Prefer unique entries when the history file reaches its limit.
setopt hist_ignore_dups       # Do not record the same command twice in a row.
setopt hist_ignore_space      # Do not record commands that begin with a Space.
setopt hist_verify            # Show expanded history commands for approval before running them.
# setopt share_history         # Enable sharing history between concurrent shells if desired.


# Format output from the `time` command.
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# Detect whether the terminal supports a colored prompt.
case "$TERM" in
    xterm-color | *-256color) color_prompt=yes ;;
esac

# Request a colored prompt when the terminal supports it.
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    # Let Powerlevel10k render the virtual environment indicator.
    VIRTUAL_ENV_DISABLE_PROMPT=1
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi

unset color_prompt force_color_prompt


# Configure the color used for history-based suggestions.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'

# Load Debian's command-not-found helper when it is installed.
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

# Additional shell options.
setopt correct # Suggest corrections for misspelled commands.
# setopt extendedglob       # Disabled because it currently conflicts with the installed NVM version.
setopt nocaseglob         # Match filenames without regard to letter case.
setopt rcexpandparam      # Expand array elements when parameters are substituted.
setopt nocheckjobs        # Do not warn when exiting with running jobs.
setopt nobeep             # Suppress the terminal bell.
setopt histignorealldups  # Remove older copies when a command is repeated.
setopt inc_append_history # Write each command to the history file immediately.

WORDCHARS=${WORDCHARS//[\/&.;]/} # Treat '/', '&', '.', and ';' as word separators.

# Additional keyboard shortcuts.
bindkey '^[[7~' beginning-of-line # Home key sequence.
bindkey '^[[H' beginning-of-line  # Home key sequence.
if [[ "${terminfo[khome]}" != "" ]]; then
    bindkey "${terminfo[khome]}" beginning-of-line # Terminal-specific Home key.
fi
bindkey '^[[8~' end-of-line # End key sequence.
bindkey '^[[F' end-of-line  # End key sequence.
if [[ "${terminfo[kend]}" != "" ]]; then
    bindkey "${terminfo[kend]}" end-of-line # Terminal-specific End key.
fi
bindkey '^[[2~' overwrite-mode                    # Insert toggles overwrite mode.
bindkey '^[[3~' delete-char                       # Delete the character under the cursor.
bindkey '^[[C' forward-char                       # Right arrow moves forward one character.
bindkey '^[[D' backward-char                      # Left arrow moves backward one character.
bindkey '^[[5~' history-beginning-search-backward # Page Up searches history by prefix.
bindkey '^[[6~' history-beginning-search-forward  # Page Down searches history by prefix.

# Navigate by word with Ctrl+Arrow shortcuts.
bindkey '^[Oc' forward-word     # Ctrl+Right in terminals using application mode.
bindkey '^[Od' backward-word    # Ctrl+Left in terminals using application mode.
bindkey '^[[1;5D' backward-word # Alternate Ctrl+Left sequence.
bindkey '^[[1;5C' forward-word  # Alternate Ctrl+Right sequence.
bindkey '^H' backward-kill-word # Ctrl+Backspace deletes the previous word.
bindkey '^[[Z' undo             # Shift+Tab undoes the last edit.

# Terminal appearance and command output styling.
autoload -U colors zcalc
colors

# Use readable colors when viewing manual pages.
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

# History substring search integration.
# Bind Up and Down to search history by the current command prefix.
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Offer to install a missing package when a command is unknown.
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then
    source /usr/share/zsh/functions/command-not-found.zsh
    export PKGFILE_PROMPT_INSTALL_MISSING=1
fi

