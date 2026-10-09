# Reusable shell functions and pager detection.

# Register the local site-functions directory with the completion system and
# generate the jc completion there on first launch. Zsh-autocomplete triggers
# compinit lazily at the first prompt, so any code sourced from .zshrc (like
# this file) is picked up by that scan.
ZSH_SITE_FUNCTIONS_DIR="$HOME/.local/share/zsh/site-functions"
if (( $+commands[jc] )); then
    if [[ ! -d "$ZSH_SITE_FUNCTIONS_DIR" ]]; then
        mkdir -p "$ZSH_SITE_FUNCTIONS_DIR"
    fi
    if [[ -w "$ZSH_SITE_FUNCTIONS_DIR" && ! -r "$ZSH_SITE_FUNCTIONS_DIR/_jc" ]]; then
        jc -Z > "$ZSH_SITE_FUNCTIONS_DIR/_jc" 2>/dev/null
    fi
    fpath=( "$ZSH_SITE_FUNCTIONS_DIR" $fpath )
fi
unset ZSH_SITE_FUNCTIONS_DIR

# Wrap "znap pull" to also check whether the Deja binary has a newer release.
# The original znap function is captured here (after Znap is sourced in
# 10-plugins.zsh) and re-exposed as a private function that the wrapper calls.
eval "__znap_original() { ${functions[znap]} }"

znap() {
    if [[ "$1" == "pull" ]]; then
        __znap_original "$@"
        typeset -i znap_rc=$?
        _deja_check_update
        return "$znap_rc"
    fi
    __znap_original "$@"
}

# Edit the Zsh history file ($HISTFILE) with the first installed editor among
# vim, micro and nano. When the editor closes cleanly, wipe the Deja database
# (db + WAL/SHM files), rebuild it from the history file alone, and restart the
# suggestion daemon detached in the background so all stale suggestions are
# flushed. Skips the Deja steps when the editor is quit without saving changes.
vimhistory() {
    local editor
    for editor in vim micro nano; do
        if (( ${+commands[$editor]} )); then
            "$editor" "$HISTFILE" || return "$?"
            # NOTE: plain "return _deja_rebuild" silently no-ops in zsh —
            # "return" arithmetic-evaluates its argument (unknown name -> 0).
            _deja_rebuild
            return "$?"
        fi
    done
    print -u2 "vimhistory: none of vim, micro or nano is installed."
    return 127
}

# Rebuild the Deja database from the Zsh history file and restart its daemon
# so the running daemon drops its old in-memory state entirely.
_deja_rebuild() {
    local deja_bin="$HOME/.local/bin/deja"
    local deja_dir="$HOME/.local/share/deja"

    [[ -x "$deja_bin" ]] || return 0

    # Empty the database, then rebuild it solely from the history file.
    # The WAL and SHM files must go too, or SQLite resurrects them on reopen.
    rm -f "$deja_dir/deja.db" "$deja_dir/deja.db-wal" "$deja_dir/deja.db-shm"
    "$deja_bin" import || return "$?"

    # Detached background restart (zsh: &! backgrounds and disowns): the
    # daemon is long-lived and hangs the terminal when run in the foreground.
    { "$deja_bin" daemon --restart >/dev/null 2>&1 < /dev/null &! }
}

# Compare the installed Deja binary against the latest GitHub release. The
# upgrade itself is handled automatically: deleting ~/.local/bin/deja and
# restarting zsh re-downloads the current release and regenerates its init.
_deja_check_update() {
    typeset deja_installed deja_latest
    typeset deja_update_bin="$HOME/.local/bin/deja"
    [[ -x "$deja_update_bin" ]] || return 0

    command -v curl >/dev/null 2>&1 || return 0

    deja_installed="$("$deja_update_bin" --version 2>/dev/null)"
    deja_installed="${deja_installed#deja }"
    deja_installed="${deja_installed%% *}"

    deja_latest="$(curl -fsSL https://api.github.com/repos/Giammarco-Ferranti/deja/releases/latest \
        | command grep '"tag_name":' | command sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
    deja_latest="${deja_latest#v}"

    if [[ "$deja_installed" != "$deja_latest" ]]; then
        print "Deja: update available ($deja_installed -> $deja_latest). Run 'rm ~/.local/bin/deja && exec zsh' to upgrade."
    else
        print "Deja: up to date ($deja_installed)."
    fi
}

# Pager selection is shared by the search, man, and fzf helpers.
# Choose batcat, bat, or less as the pager used by search and man-page helpers.
if whence -p batcat >/dev/null 2>&1; then
    _PAGER_PROG=batcat
elif whence -p bat >/dev/null 2>&1; then
    _PAGER_PROG=bat
else
    _PAGER_PROG=less
fi

# Locate the fd binary (Debian ships it as fdfind), leaving the variable empty
# so search helpers fall back to find instead of testing for aliases.
if whence -p fd >/dev/null 2>&1; then
    _FD_PROG=fd
elif whence -p fdfind >/dev/null 2>&1; then
    _FD_PROG=fdfind
else
    _FD_PROG=""
fi

# File, search, display, and terminal helpers.
# Extract one or more common archive formats.
extract() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: extract <archive> [archive ...]"
        echo "       extract --help"
        echo ""
        echo "Extract one or more supported archive files."
        echo "Supports: tar.bz2, tar.gz, tar.xz, bz2, rar, gz, tar, tbz2, tgz, zip, Z, and 7z."
        return 0
    fi

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

# Compress one or more files/directories into a specified archive format.
compress() {
    if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 2 ]]; then
        echo "Usage: compress <archive_name> <file_or_dir> [file_or_dir ...]"
        echo "       compress --help"
        echo ""
        echo "Compress target file(s) or directory(ies) into an archive."
        echo "Supports: .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .tar, .zip, .7z, .rar, .gz, .bz2"
        return 0
    fi

    local archive="$1"
    shift # Remove the archive name from the argument list

    # Check that all remaining source files/directories exist
    for source in "$@"; do
        if [[ ! -e "$source" ]]; then
            echo "'$source' does not exist!"
            return 1
        fi
    done

    case "$archive" in
        *.tar.gz | *.tgz) tar czvf "$archive" "$@" ;;
        *.tar.bz2 | *.tbz2) tar cjvf "$archive" "$@" ;;
        *.tar.xz) tar cJvf "$archive" "$@" ;;
        *.tar) tar cvf "$archive" "$@" ;;
        *.zip) zip -r "$archive" "$@" ;;
        *.7z) 7z a "$archive" "$@" ;;
        *.rar) rar a "$archive" "$@" ;;
        *.gz)
            if [[ $# -gt 1 || -d "$1" ]]; then
                echo "Error: .gz can only compress a single file directly. Use .tar.gz for multiple files or directories."
                return 1
            fi
            gzip -k "$1" # -k keeps original file
            ;;
        *.bz2)
            if [[ $# -gt 1 || -d "$1" ]]; then
                echo "Error: .bz2 can only compress a single file directly. Use .tar.bz2 for multiple files or directories."
                return 1
            fi
            bzip2 -k "$1" # -k keeps original file
            ;;
        *)
            echo "Unsupported archive format for '$archive'!"
            return 1
            ;;
    esac
}

# Search files in the current directory or specified path for a text pattern.
ftext() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: ftext [options] <pattern> [file_or_dir]"
        echo "       ftext --help"
        echo ""
        echo "Search files in the current directory or specified path for a text pattern."
        echo "Options:"
        echo "  --no-ignore  Include files normally ignored by ripgrep/fd."
        echo "  --no-color   Disable colored search output."
        return 0
    fi

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
        echo "Usage: ftext [options] <pattern> [file_or_dir]"
        return 1
    fi

    local target_dir="."
    if [[ -n "$2" ]]; then
        if [[ -f "$2" ]]; then
            case "${_PAGER_PROG}" in
                batcat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | batcat --style=plain || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | batcat --style=plain ;;
                bat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | bat --style=plain || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | bat --style=plain ;;
                *) command -v rg >/dev/null 2>&1 && rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$2" | less || grep -iIHn ${COLOR_OPT} -- "$1" "$2" | less ;;
            esac
            return $?
        elif [[ -d "$2" ]]; then
            target_dir="$2"
        else
            echo "Path '$2' not found" >&2
            return 1
        fi
    fi

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | batcat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | bat --style=plain || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | bat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | bat --style=plain || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | less || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r rg --hidden -i -n ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" | less
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -0 -d 1 -t f ${NO_IGNORE_OPT} . "$target_dir" | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | less || find "$target_dir" -maxdepth 1 -type f -print0 | xargs -0 -r grep -iIHn ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Search recursively from the current directory or specified path for a text pattern.
frtext() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: frtext [options] <pattern> [directory]"
        echo "       frtext --help"
        echo ""
        echo "Search recursively from the current directory or specified path for a text pattern."
        echo "Options:"
        echo "  --no-ignore  Include files normally ignored by ripgrep."
        echo "  --no-color   Disable colored search output."
        return 0
    fi

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
        echo "Usage: frtext [options] <pattern> [directory]"
        return 1
    fi

    local target_dir="."
    if [[ -n "$2" ]]; then
        if [[ ! -d "$2" ]]; then
            echo "Directory '$2' not found" >&2
            return 1
        fi
        target_dir="$2"
    fi

    case "${_PAGER_PROG}" in
        batcat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$target_dir" | batcat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" "$target_dir" | batcat --style=plain ;;
        bat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$target_dir" | bat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" "$target_dir" | bat --style=plain ;;
        *) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" "$target_dir" | less || grep -iIHRn ${COLOR_OPT} -- "$1" "$target_dir" | less ;;
    esac
}

# Find a filename in the current directory or specified directory.
ffile() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: ffile [options] <name-pattern> [directory]"
        echo "       ffile --help"
        echo ""
        echo "Find a filename in the current directory or specified directory."
        echo "Options:"
        echo "  --no-ignore  Include files normally ignored by ripgrep/fd."
        echo "  --no-color   Disable colored search output."
        echo "  -d           Search directories instead of files."
        return 0
    fi

    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a FD_TYPE_OPT
    local -a FIND_TYPE_OPT
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
            -d)
                FD_TYPE_OPT=(-t d)
                FIND_TYPE_OPT=(-type d)
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
        echo "Usage: ffile [options] <name-pattern> [directory]"
        return 1
    fi

    local target_dir="."
    if [[ -n "$2" ]]; then
        if [[ ! -d "$2" ]]; then
            echo "Directory '$2' not found" >&2
            return 1
        fi
        target_dir="$2"
    fi

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -d 1 -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less || find "$target_dir" -maxdepth 1 -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Find a filename recursively below the current directory or specified directory.
frfile() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: frfile [options] <name-pattern> [directory]"
        echo "       frfile --help"
        echo ""
        echo "Find a filename recursively below the current directory or specified directory."
        echo "Options:"
        echo "  --no-ignore  Include files normally ignored by ripgrep/fd."
        echo "  --no-color   Disable colored search output."
        echo "  -d           Search directories instead of files."
        return 0
    fi

    local NO_IGNORE_OPT=""
    local COLOR_OPT="--color=always"
    local -a FD_TYPE_OPT
    local -a FIND_TYPE_OPT
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
            -d)
                FD_TYPE_OPT=(-t d)
                FIND_TYPE_OPT=(-type d)
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
        echo "Usage: frfile [options] <name-pattern> [directory]"
        return 1
    fi

    local target_dir="."
    if [[ -n "$2" ]]; then
        if [[ ! -d "$2" ]]; then
            echo "Directory '$2' not found" >&2
            return 1
        fi
        target_dir="$2"
    fi

    case "${_PAGER_PROG}" in
        batcat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | batcat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | batcat --style=plain
            fi
            ;;
        bat)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | bat --style=plain
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | bat --style=plain
            fi
            ;;
        *)
            if command -v rg >/dev/null 2>&1; then
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | rg --hidden -i ${NO_IGNORE_OPT} ${COLOR_OPT} -- "$1" | less
            else
                [[ -n "${_FD_PROG}" ]] && "${_FD_PROG}" --hidden -L -i "$1" ${FD_TYPE_OPT} ${NO_IGNORE_OPT} . "$target_dir" 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less || find "$target_dir" -iname "*$1*" ${FIND_TYPE_OPT} 2>/dev/null | grep -i ${COLOR_OPT} -- "$1" | less
            fi
            ;;
    esac
}

# Copy a file while showing rsync progress.
cpp() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: cpp <source> <destination>"
        echo "       cpp --help"
        echo ""
        echo "Copy a file or directory while showing rsync progress."
        return 0
    fi

    rsync -avh --progress "$1" "$2"
}

# List directories with icons.
ld() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: ld [directory ...]"
        echo "       ld --help"
        echo ""
        echo "List directories with icons. With no arguments, list directories in the current directory."
        return 0
    fi

    if (($#)); then eza -d --group-directories-first --icons=auto "$@"; else eza -D --group-directories-first --icons=auto; fi
}

# List all directories, including hidden ones, with icons.
lad() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: lad [directory ...]"
        echo "       lad --help"
        echo ""
        echo "List all directories, including hidden ones, with icons."
        return 0
    fi

    if (($#)); then eza -ad --group-directories-first --icons=auto "$@"; else eza -aD --group-directories-first --icons=auto; fi
}

# Show a detailed listing of directories with icons.
lld() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: lld [directory ...]"
        echo "       lld --help"
        echo ""
        echo "Show detailed directory listings with icons."
        return 0
    fi

    if (($#)); then eza -alhgd --group-directories-first --icons=auto "$@"; else eza -alhgD --group-directories-first --icons=auto; fi
}

# Show detailed directory listings recursively with icons.
lltd() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: lltd [directory ...]"
        echo "       lltd --help"
        echo ""
        echo "Show detailed recursive directory listings with icons."
        return 0
    fi

    if (($#)); then eza -alhgTd --group-directories-first --icons=auto "$@"; else eza -alhgTD --group-directories-first --icons=auto; fi
}

# Show detailed directory listings with total sizes.
llld() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: llld [directory ...]"
        echo "       llld --help"
        echo ""
        echo "Show detailed directory listings with total sizes and icons."
        return 0
    fi

    if (($#)); then eza -alhgd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgD --group-directories-first --total-size --icons=auto; fi
}

# Show recursive directory listings with total sizes.
llltd() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: llltd [directory ...]"
        echo "       llltd --help"
        echo ""
        echo "Show recursive directory listings with total sizes and icons."
        return 0
    fi

    if (($#)); then eza -alhgTd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgTD --group-directories-first --total-size --icons=auto; fi
}

# Display manual pages through the selected pager.
man() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: man <page> [section]"
        echo "       man --help"
        echo ""
        echo "Display a manual page through the configured pager."
        return 0
    fi

    case "${_PAGER_PROG}" in
        batcat) command man "$@" | col -bx | batcat --language=man --paging=always --style=plain ;;
        bat) command man "$@" | col -bx | bat --language=man --paging=always --style=plain ;;
        *) command man "$@" ;;
    esac
}

# Create a file or stream of random data with the requested size.
mktext() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: mktext [-f] [-r] [-s] [-p] <size> [filename]"
        echo "       mktext --help"
        echo ""
        echo "Create a file or stream of random data with the requested size."
        echo "Options:"
        echo "  -f  Overwrite an existing output file."
        echo "  -r  Use raw random bytes instead of printable characters."
        echo "  -s  Include symbols in generated printable data."
        echo "  -p  Create missing parent directories for the output file."
        echo "Sizes may use bytes, K/M/G/T, or KiB/MiB/GiB/TiB units."
        return 0
    fi

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

# Create a tmux session with a randomly generated name.
t() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: t"
        echo "       t --help"
        echo ""
        echo "Create a tmux session with a randomly generated unused name and attach to it."
        return 0
    fi

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

    # Keep generating names until an unused session name is found.
    while true; do
        a=${adjs[$((RANDOM % ${#adjs[@]} + 1))]}
        n=${animals[$((RANDOM % ${#animals[@]} + 1))]}
        session="${a}_${n}"

        # Skip names already used by another tmux session.
        if ! tmux has-session -t "$session" 2>/dev/null; then
            break
        fi
    done

    tmux new-session -s "$session" -n shell
}

# Attach to a named tmux session, creating it when necessary.
taa() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: taa [session-name]"
        echo "       taa --help"
        echo ""
        echo "Attach to a named tmux session, creating it when necessary."
        echo "Defaults to the session name 'main'."
        return 0
    fi

    local name="$1"
    [ -z "$name" ] && name="main"
    tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" || tmux new -n shell -s "$name"
}

# Run a command in a detached tmux session and append its output to a log.
tbg() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: tbg <session-name> <command> [argument ...]"
        echo "       tbg --help"
        echo ""
        echo "Run a command in a detached tmux session and append its output to ~/tmux-logs/<session-name>.log."
        return 0
    fi

    local name="$1"
    shift
    local logfile="$HOME/tmux-logs/${name}.log"
    mkdir -p "$HOME/tmux-logs"
    tmux new-session -d -s "$name" "{ echo \"[Started at: \$(date)]\"; $@ 2>&1; echo \"[Finished at: \$(date)]\"; } | tee -a \"$logfile\""
    echo -e "Started detached tmux job '$name'\nLogging to: $logfile"
}

# Choose a tmux session with fzf and attach to it.
tsp() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: tsp"
        echo "       tsp --help"
        echo ""
        echo "Choose a tmux session with fzf and attach to it."
        return 0
    fi

    local session
    session=$(tmux ls -F '#S' | fzf) || return
    tmux attach -t "$session"
}

# Switch to the most recently used tmux session.
tlast() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: tlast"
        echo "       tlast --help"
        echo ""
        echo "Switch to the most recently used tmux session, or attach to the newest session."
        return 0
    fi

    if [ -n "$TMUX" ]; then tmux switch-client -l 2>/dev/null && return; fi
    local session=$(tmux ls -F "#{session_created} #{session_name}" 2>/dev/null | sort -nr | awk 'NR==1 {print $2}')
    if [ -n "$session" ]; then tmux attach -t "$session"; else echo "No tmux sessions found"; fi
}

# Create a tmux session and log output from all panes.
tnl() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: tnl <session-name>"
        echo "       tnl --help"
        echo ""
        echo "Create a tmux session and log output from all panes to ~/tmux-logs/<session-name>.log."
        return 0
    fi

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

# Provide completion candidates for tmux session names.
_tp_sessions() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: _tp_sessions"
        echo "       _tp_sessions --help"
        echo ""
        echo "Provide tmux session names for shell completion."
        return 0
    fi

    local -a sessions
    sessions=("${(@f)$(tmux ls -F '#S' 2>/dev/null)}")
    _describe 'tmux sessions' sessions
}

# Print the last requested number of lines from a tmux pane.
tp() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: tp <num-lines> <session-name>"
        echo "       tp --help"
        echo ""
        echo "Print the requested number of lines from a tmux pane."
        return 0
    fi

    local lines="$1" session="$2"
    if [ -z "$lines" ] || [ -z "$session" ]; then
        echo "Usage: tp <num-lines> <session-name>"
        return 1
    fi
    tmux capture-pane -p -t "$session" | tail -n "$lines"
}

# Let Yazi change the current shell directory after navigation.
function y() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: y [yazi-options ...]"
        echo "       y --help"
        echo ""
        echo "Launch Yazi and change the current shell directory after navigation."
        return 0
    fi

    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Inspect and format the contents and attributes of a Zsh variable, credits @ysap.
vardump() {
    emulate -L zsh

    # Parse command-line options.
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

    # Print usage information when requested.
    if [[ $_vd_show_help == true ]]; then
        echo "Usage: vardump [-v] [-C when] <variable_name>"
        echo "       vardump --help"
        echo
        echo "Inspect and format the contents and attributes of a Zsh variable."
        echo
        echo "Options:"
        echo "  -v           Verbose output (displays attributes, header/footer, and length)."
        echo "  -C WHEN      Colorize output: 'always', 'never', or 'auto' (default: auto)."
        echo "  -h, --help   Display this help message."
        return 0
    fi

    # Read the variable name supplied by the caller.
    local _vd_target=$1

    if [[ -z $_vd_target ]]; then
        echo 'vardump: name required as first argument' >&2
        echo 'Try "vardump --help" for more information.' >&2
        return 1
    fi

    # Stop if the requested variable does not exist.
    if ! typeset -p "$_vd_target" &>/dev/null; then
        echo "variable ${(q+)_vd_target} not defined" >&2
        return 1
    fi

    # Select colors when output is interactive or explicitly requested.
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

    # Print the optional verbose header.
    if $_vd_verbose; then
        echo "${color_dim}--------------------------${color_rst}"
        echo "${color_dim}vardump: ${color_rst}$_vd_target"
    fi

    # Read the variable type and attributes using Zsh parameter flags.
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

    # Print the optional attribute summary.
    if $_vd_verbose; then
        echo -n "${color_dim}attributes: ${color_rst}"
        if ((${#_vd_attributes} > 0)); then
            echo "${(j:/:)_vd_attributes}"
        else
            echo '(none)'
        fi
    fi

    # Print the variable contents in a type-aware format.
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
            printf '    [%s]=%s\n' \
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
            printf '    [%s]=%s\n' \
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

# Resolve the Podman container ID publishing a given host port.
# Podman has no Docker-style "publish" ps filter, so query port mappings instead.
_podman_cid_for_port() {
    local want_port="$1" cid="" container
    [[ -z "$want_port" ]] && return 0

    # `podman port --all` prints "<container-id>\t<container-port> -> <ip>:<host-port>".
    cid=$(podman port --all 2>/dev/null | awk -v re=":${want_port}\$" '$NF ~ re {print $1; exit}')

    # Fallback for Podman versions without `port --all`: inspect each container.
    if [[ -z "$cid" ]]; then
        for container in ${(f)"$(podman ps -q 2>/dev/null)"}; do
            if podman inspect "$container" \
                --format '{{range $p, $b := .NetworkSettings.Ports}}{{range $b}}{{.HostPort}}{{"\n"}}{{end}}{{end}}' \
                2>/dev/null | grep -qx "$want_port"; then
                cid="$container"
                break
            fi
        done
    fi

    print -r -- "$cid"
}

# Show information about a port and the process using it.
portinfo() {
    # Help flag check
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: portinfo [port]"
        echo "       portinfo --help"
        echo ""
        echo "Displays process, working directory, parent hierarchy, and container details for a port."
        echo "If run without arguments, interactively prompts for the port number."
        echo "Supports redirection (e.g., portinfo 8080 > report.txt)."
        return 0
    fi

    local port="$1"

    # Prompt interactively if no port is provided
    if [[ -z "$port" ]]; then
        read "port?Enter port number: "
        if [[ -z "$port" ]]; then
            echo "No port entered. Aborting." >&2
            return 1
        fi
    fi

    # Validate numeric port range
    if [[ ! "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
        echo "Error: '$port' is not a valid port number (1-65535)." >&2
        return 1
    fi

    local pids
    pids=($(sudo lsof -ti :"$port" 2>/dev/null))

    if [[ ${#pids[@]} -eq 0 ]]; then
        echo "No active process found on port $port"
        return 0
    fi

    echo "Port $port details:"
    for pid in "${pids[@]}"; do
        local cmd=$(ps -p "$pid" -o command= 2>/dev/null | xargs)

        # Resolve the exact IP:Port binding for this PID (e.g., 127.0.0.1:8080 or *:8080)
        local addr=$(sudo lsof -a -p "$pid" -i :"$port" -P -n -Fn 2>/dev/null | sed -n 's/^n\([^ ]*\).*/\1/p' | head -n 1)
        [[ -z "$addr" ]] && addr="*:$port"

        echo "----------------------------------------"
        echo "PID:     $pid"
        echo "Address: $addr"
        echo "Command: $cmd"

        # Check working directory
        if command -v pwdx >/dev/null 2>&1; then
            echo "CWD:     $(sudo pwdx "$pid" 2>/dev/null | cut -d' ' -f2-)"
        else
            echo "CWD:     $(sudo lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')"
        fi

        # Trace parent processes up to PID 1
        local parent_chain=()
        local curr_pid="$pid"
        while true; do
            local ppid=$(ps -p "$curr_pid" -o ppid= 2>/dev/null | xargs)
            if [[ -z "$ppid" || "$ppid" -eq 0 || "$ppid" -eq "$curr_pid" ]]; then
                break
            fi
            parent_chain+=("$ppid")
            curr_pid="$ppid"
        done

        if [[ ${#parent_chain[@]} -gt 0 ]]; then
            echo "Parent Process Chain:"
            for ppid in "${parent_chain[@]}"; do
                local pcmd=$(ps -p "$ppid" -o command= 2>/dev/null | xargs)
                echo "  ↳ PID $ppid: $pcmd"
            done
        fi

        # Extract cgroups for Docker and Podman container IDs (Linux)
        local docker_cid="" podman_cid=""
        if [[ -f "/proc/$pid/cgroup" ]]; then
            docker_cid=$(grep -oE '(docker-|/docker/)[0-9a-f]{12,64}' "/proc/$pid/cgroup" 2>/dev/null | head -n 1 | sed -E 's/(docker-|\/docker\/)//;s/\.scope//')
            podman_cid=$(grep -oE '(libpod-|/libpod/)[0-9a-f]{12,64}' "/proc/$pid/cgroup" 2>/dev/null | head -n 1 | sed -E 's/(libpod-|\/libpod\/)//;s/\.scope//')
        fi

        local fmt_str="ID:      {{.ID}}\nName:    {{.Names}}\nImage:   {{.Image}}\nStatus:  {{.Status}}"

        # Inspect Docker
        if command -v docker >/dev/null 2>&1; then
            if [[ -n "$docker_cid" ]]; then
                echo "Docker Container Details:"
                sudo docker ps --filter "id=$docker_cid" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
            elif [[ "$cmd" == *"docker-proxy"* ]]; then
                echo "Docker Container Details:"
                sudo docker ps --filter "publish=$port" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
            fi
        fi

        # Inspect Podman
        if command -v podman >/dev/null 2>&1; then
            # Fall back to the conmon command line when the cgroup gave no ID.
            if [[ -z "$podman_cid" && "$cmd" == *"conmon"* ]]; then
                podman_cid=$(echo "$cmd" | grep -oE '\-c [0-9a-f]{12,64}' | awk '{print $2}' | head -n 1)
            fi

            # Rootless port forwarding is handled by pasta/rootlessport, which
            # live outside the container cgroup, so resolve the container by its
            # published host port instead. Podman has no Docker-style "publish"
            # ps filter, hence the helper.
            if [[ -z "$podman_cid" && ("$cmd" == *"pasta"* || "$cmd" == *"rootlessport"* || "$cmd" == *"podman"* || "$cmd" == *"conmon"*) ]]; then
                podman_cid=$(_podman_cid_for_port "$port")
            fi

            if [[ -n "$podman_cid" ]]; then
                echo "Podman Container Details:"
                podman ps --filter "id=$podman_cid" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
            fi
        fi
    done
    echo "----------------------------------------"
}

# Show ports used by a process and its children.
processinfo() {
    # Help flag check
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: processinfo [PID] [> output.txt]"
        echo "       processinfo --help"
        echo ""
        echo "Displays process details, working directory, parent hierarchy, active network ports (for main process and children), and container info (Docker/Podman)."
        echo "If run without arguments, launches an interactive process search."
        echo "Supports redirection (e.g., processinfo > report.txt)."
        return 0
    fi

    local main_pid="$1"

    # Interactive search mode if no PID is provided
    if [[ -z "$main_pid" ]]; then
        local search_term
        read "search_term?Enter process name or term to search: "

        if [[ -z "$search_term" ]]; then
            echo "No search term entered. Aborting." >&2
            return 1
        fi

        # Find matching PIDs (case-insensitive full command match)
        local -a matches=($(pgrep -i -f "$search_term" 2>/dev/null))

        if [[ ${#matches[@]} -eq 0 ]]; then
            echo "No processes found matching '$search_term'." >&2
            return 1
        fi

        echo "\nMatching processes for '$search_term':" >&2
        local i=1
        for m in "${matches[@]}"; do
            local cmd=$(ps -p "$m" -o command= 2>/dev/null | xargs)
            echo "  [$i] PID $m: $cmd" >&2
            ((i++))
        done

        local choice
        read "choice?Select process number (1-${#matches[@]}): "

        if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#matches[@]})); then
            echo "Invalid selection. Aborting." >&2
            return 1
        fi

        main_pid="${matches[$choice]}"
    fi

    # Validate selected/provided PID
    if ! ps -p "$main_pid" >/dev/null 2>&1; then
        echo "Error: Process ID '$main_pid' not found." >&2
        return 1
    fi

    local main_cmd=$(ps -p "$main_pid" -o command= 2>/dev/null | xargs)

    # Check working directory (CWD / PWD)
    local main_cwd=""
    if command -v pwdx >/dev/null 2>&1; then
        main_cwd=$(sudo pwdx "$main_pid" 2>/dev/null | cut -d' ' -f2-)
    else
        main_cwd=$(sudo lsof -a -p "$main_pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
    fi

    # Trace parent process chain up to PID 1
    local parent_chain=()
    local curr_pid="$main_pid"
    while true; do
        local ppid=$(ps -p "$curr_pid" -o ppid= 2>/dev/null | xargs)
        if [[ -z "$ppid" || "$ppid" -eq 0 || "$ppid" -eq "$curr_pid" ]]; then
            break
        fi
        parent_chain+=("$ppid")
        curr_pid="$ppid"
    done

    # Print inspected process overview
    echo "\nProcess Details for PID $main_pid:"
    echo "----------------------------------------"
    echo "PID:     $main_pid"
    echo "Command: $main_cmd"
    echo "CWD:     $main_cwd"

    if [[ ${#parent_chain[@]} -gt 0 ]]; then
        echo "Parent Process Chain:"
        for ppid in "${parent_chain[@]}"; do
            local pcmd=$(ps -p "$ppid" -o command= 2>/dev/null | xargs)
            echo "  ↳ PID $ppid: $pcmd"
        done
    fi

    # Collect target PID and all descendant child PIDs recursively
    local -a pids=("$main_pid")
    local -a queue=("$main_pid")

    while ((${#queue} > 0)); do
        local curr="${queue[1]}"
        shift queue
        local children=($(pgrep -P "$curr" 2>/dev/null))
        for child in "${children[@]}"; do
            pids+=("$child")
            queue+=("$child")
        done
    done

    echo "\nNetwork ports for PID $main_pid and child processes:"
    echo "----------------------------------------"

    local found=0
    for pid in "${pids[@]}"; do
        local sockets=$(sudo lsof -a -p "$pid" -i -P -n 2>/dev/null)

        if [[ -n "$sockets" ]]; then
            found=1
            local cmd=$(ps -p "$pid" -o command= 2>/dev/null | xargs)

            # Dynamic indentation based on hierarchy
            local s_indent="  "
            local c_indent="    "

            if [[ "$pid" -eq "$main_pid" ]]; then
                echo "Main PID $pid: $cmd"
            else
                echo "  Child PID $pid: $cmd"
                s_indent="    "
                c_indent="      "
            fi

            echo "$sockets" | awk -v pad="$s_indent" 'NR>1 {printf "%s%-6s %-6s %s\n", pad, $5, $8, $9}'

            # --- Container Inspection (Docker & Podman) ---
            local docker_cid="" podman_cid=""

            if [[ -f "/proc/$pid/cgroup" ]]; then
                docker_cid=$(grep -oE '(docker-|/docker/)[0-9a-f]{12,64}' "/proc/$pid/cgroup" 2>/dev/null | head -n 1 | sed -E 's/(docker-|\/docker\/)//;s/\.scope//')
                podman_cid=$(grep -oE '(libpod-|/libpod/)[0-9a-f]{12,64}' "/proc/$pid/cgroup" 2>/dev/null | head -n 1 | sed -E 's/(libpod-|\/libpod\/)//;s/\.scope//')
            fi

            local fmt_str="ID:      {{.ID}}\nName:    {{.Names}}\nImage:   {{.Image}}\nStatus:  {{.Status}}"

            # Check Docker
            if command -v docker >/dev/null 2>&1; then
                if [[ -n "$docker_cid" ]]; then
                    echo "${s_indent}Docker Container Details:"
                    sudo docker ps --filter "id=$docker_cid" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                elif [[ "$cmd" == *"docker-proxy"* ]]; then
                    local host_port=$(echo "$cmd" | grep -oE '\-host-port [0-9]+' | awk '{print $2}')
                    if [[ -n "$host_port" ]]; then
                        echo "${s_indent}Docker Container Details:"
                        sudo docker ps --filter "publish=$host_port" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                    fi
                fi
            fi

            # Check Podman
            if command -v podman >/dev/null 2>&1; then
                # Fall back to the conmon command line when the cgroup gave no ID.
                if [[ -z "$podman_cid" && "$cmd" == *"conmon"* ]]; then
                    podman_cid=$(echo "$cmd" | grep -oE '\-c [0-9a-f]{12,64}' | awk '{print $2}' | head -n 1)
                fi

                # Rootless port forwarding is handled by pasta/rootlessport, which
                # live outside the container cgroup, so resolve the container by its
                # local listening port. Podman has no Docker-style "publish" ps
                # filter, hence the helper.
                if [[ -z "$podman_cid" && ("$cmd" == *"pasta"* || "$cmd" == *"rootlessport"* || "$cmd" == *"podman"* || "$cmd" == *"conmon"*) ]]; then
                    local bound_port=$(echo "$sockets" | awk '/\(LISTEN\)/ {print $9}' | grep -oE '[0-9]+$' | head -n 1)
                    [[ -n "$bound_port" ]] && podman_cid=$(_podman_cid_for_port "$bound_port")
                fi

                if [[ -n "$podman_cid" ]]; then
                    echo "${s_indent}Podman Container Details:"
                    podman ps --filter "id=$podman_cid" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                fi
            fi

            echo ""
        fi
    done

    if ((! found)); then
        echo "No open network ports found for PID $main_pid or its children."
    fi
    echo "----------------------------------------"
}

# Complete the line count and tmux session arguments for tp.
compdef '_arguments "1: : " "2:tmux session:_tp_sessions"' tp

# ─── Nushell-style structured data (jc + jq) ──────────────────────────────
# Producers turn ordinary command output into JSON arrays of records via jc;
# verbs transform a JSON array that arrives on stdin, so they chain freely:
#   psq | where mem_percent '>' 1 | sel pid mem_percent command |
#     sort-by mem_percent desc | first 5 | pretty
# Every producer and verb supports --help (only; no -h, so lsq can use -h
# for human-readable sizes). Notes on the verb names:
#   - "sort-by" is the real Nushell verb (bare "sort" would shadow
#     /usr/bin/sort), and "sel" replaces "select" because select is a Zsh
#     reserved word that cannot be used as a function name.
#   - "where" shadows the Zsh builtin where (command lookup, like which).

help_check() {
    [[ "$1" == "--help" ]]
}

# Running processes as JSON records (pid, user, cpu_percent, mem_percent, command, ...).
psq() {
    help_check "$1" && {
        echo "Usage: psq | psq --help"
        echo ""
        echo "Running processes as JSON records via 'ps aux | jc --ps'."
        echo "Fields: pid, user, cpu_percent, mem_percent, rss, vsz, tty, stat, start, time, command, ..."
        return 0
    }
    ps aux | jc --ps
}

# Current directory listing as JSON records (filename, flags, size, owner, date, ...).
# -h makes sizes human-readable (K/M/G) instead of raw bytes.
lsq() {
    # jc --ls dates ("Oct 9 11:55" / "Oct 9 2025") do not sort; rewrite
    # them to ISO-like "YYYY-MM-DD HH:MM" so sort-by date works.
    local jqdate='(
        def mnum: {"Jan":1,"Feb":2,"Mar":3,"Apr":4,"May":5,"Jun":6,
                   "Jul":7,"Aug":8,"Sep":9,"Oct":10,"Nov":11,"Dec":12};
        map(
            (.date // "" | split(" ")) as $p |
            (($p[2] // "") | test("^[0-9]{4}$")) as $hasyear |
            ((mnum[$p[0]] // 1) |
                if . < 10 then "0" + tostring else tostring end) as $mo |
            (($p[1] // "1") | if length == 1 then "0" + . else . end) as $dd |
            .date = ((if $hasyear then ($p[2] // "")
                  else (now | strftime("%Y")) end)
                 + "-" + $mo + "-" + $dd
                 + " " + (if $hasyear then "00:00"
                  else ($p[2] // "00:00") end))
    )
)'
    if [[ "$1" == "-h" ]]; then
        # jc --ls cannot parse humanReadable sizes reliably ("4.0K" -> 4),
        # so keep byte sizes from `ls -la` and humanize them here.
        ls -la | jc --ls | jq '
            def human:
                if type != "number" then .
                elif . >= 1073741824 then ((. / 1073741824 * 100) | round / 100 | tostring) + "G"
                elif . >= 1048576 then ((. / 1048576 * 100) | round / 100 | tostring) + "M"
                elif . >= 1024 then ((. / 1024 * 100) | round / 100 | tostring) + "K"
                else tostring end;
            map(if .size | type == "number" then .size = (.size | human) else . end)' | jq "$jqdate"
        return 0
    fi
    help_check "$1" && {
        echo "Usage: lsq [-h]"
        echo "       lsq --help"
        echo ""
        echo "Current directory listing as JSON records via 'ls -la | jc --ls'."
        echo "Fields: filename, flags, mode, owner, group, size, date, ..."
        echo "Dates are rewritten to ISO-like 'YYYY-MM-DD HH:MM' strings, so"
        echo "'sort-by date' sorts chronologically (recent files infer the"
        echo "current year from ls; year-form dates become 00:00)."
        echo "With -h, sizes are humanized to K/M/G from the raw byte sizes."
        return 0
    }
    ls -la | jc --ls | jq "$jqdate"
}

# Mounted filesystems as JSON records (filesystem, size, used, use_percent, ...).
dfq() {
    help_check "$1" && {
        echo "Usage: dfq | dfq --help"
        echo ""
        echo "Mounted filesystems as JSON records via 'df -h | jc --df'."
        echo "Fields: filesystem, total, used, free, use_percent, free_percent, capacity, path"
        return 0
    }
    df -h | jc --df
}

# Directory tree sizes as JSON records (path, size).
duq() {
    help_check "$1" && {
        echo "Usage: duq [path]"
        echo "       duq --help"
        echo ""
        echo "Directory tree sizes as JSON records via 'du -ab <path> | jc --du'."
        echo "Fields: path, size (bytes). Defaults to the current directory."
        return 0
    }
    du -ab "${1:-.}" | jc --du
}

# Memory usage as JSON records (total, free, available, ...).
freeq() {
    help_check "$1" && {
        echo "Usage: freeq | freeq --help"
        echo ""
        echo "Memory usage as JSON records via 'free -b | jc --free'."
        echo "Fields: type, total, used, free, available, shared, buffers, cached"
        return 0
    }
    free -b | jc --free
}

# Active and listening sockets as JSON records (netid, state, local_address, ...).
ssq() {
    help_check "$1" && {
        echo "Usage: ssq | ssq --help"
        echo ""
        echo "Active and listening sockets as JSON records via 'ss -a | jc --ss'."
        echo "Fields: netid, state, recvq, sendq, local_address, local_port, peer_address, peer_port, process"
        return 0
    }
    ss -a | jc --ss
}

# Current boot journal (or custom journalctl args) as JSON records.
# Use -s/--sudo as the FIRST argument when the journal needs root access.
journalq() {
    help_check "$1" && {
        echo "Usage: journalq [--sudo] [journalctl args...]"
        echo "       journalq --help"
        echo ""
        echo "Journal entries as JSON records via 'journalctl --no-pager -q -o json | jq -s'."
        echo ""
        echo "With no args, defaults to the current boot (-b). Extra args are passed to"
        echo "journalctl verbatim, e.g.:"
        echo "    journalq -r                 # reverse order"
        echo "    journalq -u nginx.service   # one unit, all boots"
        echo "    journalq --since -1h        # last hour"
        echo "    journalq --sudo -b -1       # previous boot (needs root)"
        echo "Prefix the call with -s/--sudo (as the first argument) to run under sudo."
        echo ""
        echo "Fields: ts (ISO 8601; empty timestamps fall back to epoch), prio (0-7, missing falls back to 6), id, unit, pid, msg"
        echo "Usage:  journalq | where prio '<=' 4 | sort-by ts desc | first 10 | pretty"
        echo "        journalq -u ssh | where id contains \"sshd\" | pretty"
        echo "        journalq | get id | sort | uniq -c | sort -rn | head"
        return 0
    }
    local use_sudo=0
    if [[ "$1" == "-s" || "$1" == "--sudo" ]]; then
        use_sudo=1
        shift
    fi
    local -a jargs
    if (($# > 0)); then
        jargs=("$@")                 # verbatim journalctl pass-through
    else
        jargs=(-b)
    fi
    local -a cmd
    if (($use_sudo)); then
        cmd=(sudo journalctl)
    else
        cmd=(journalctl)
    fi
    "${cmd[@]}" --no-pager -q -o json "${jargs[@]}" | jq -s '
        def strv:
            if type == "array" then (try implode catch "?")
            elif type == "null" then ""
            else . end;
        map({
            # empty/missing numeric fields would explode bare tonumber;
            # ts falls back to epoch 1970 (sorts last on desc), prio to 6 (info)
            ts:   (."__REALTIME_TIMESTAMP" | strv | (tonumber? // 0) / 1000000 | todateiso8601),
            prio: (.PRIORITY | strv | tonumber? // 6),
            id:   ((._COMM // .SYSLOG_IDENTIFIER // "?") | strv | ascii_downcase),
            unit: ((._SYSTEMD_UNIT // "") | strv),
            pid:  ((._PID // "") | strv | tonumber? // ""),
            msg:  ((.MESSAGE | strv) | gsub("\n"; " "))
        })'
}

# Split stdin lines into JSON records with a custom separator.
# The separator accepts printf %b escapes, including hex bytes (\t = \x09);
# find raw separators with e.g. 'xxd somelog | head' and pass '\xHH' here.
sep() {
    help_check "$1" && {
        echo "Usage: sep [sep] <field>... | sep --help"
        echo ""
        echo "Split each stdin line by <sep> and build JSON records with the given"
        echo "field names in order. Splitting STOPS once every field has a value:"
        echo "any extra separators (e.g. colons inside the text) stay in the"
        echo "last field, so the last field 'absorbs' the remainder."
        echo "With a single argument (no separator), each whole line becomes the"
        echo "value of that one field. Numeric-looking values are auto-converted"
        echo "to numbers. ANSI color escapes in the data are stripped first (so"
        echo "'where' on numbers works with colored output). Blank lines are skipped."
        echo ""
        printf '%s\n' \
            "Separator forms (quote them so the shell passes them raw):" \
            "  ','      comma" \
            "  '\t'     tab (printf escape)" \
            "  '\x1f'   hex byte (pair with 'xxd file | head' to find one)" \
            "  ' -- '   literal substring"
        printf '%s\n' \
            "Field-name prefixes:" \
            "  '^path'     right-anchored split: all following fields are counted" \
            "              from the END of the line, and the first field gets the" \
            "              whole remainder (rg-style path:line:snippet where the" \
            "              path itself may contain the separator)." \
            "  '*snippet'  explicit marker for the default remainder behavior on the" \
            "              last field (kept only for readability/wrapping apps that" \
            "              used it before)." \
            "Prefixes cannot be combined, and are only allowed on the first (^)" \
            "or last (*) field. Caveat: '^' counts all following fields from" \
            "the END of the line, so those fields themselves must not contain" \
            "the separator; the LAST field may contain it (remainder is kept" \
            "there by default), but all MIDDLE fields must not." \
            "Tip: to keep a whole line as one field (e.g. paths with spaces" \
            "under sep ' '), use a separator that never occurs," \
            "e.g. sep '\x01' path."
        echo "Usage: sep ':' '^path line snippet' < rg-output.txt | where line '>=' 190 | pretty"
        echo "       sep ':' file line '*snippet' < rg-output.txt | pretty"
        echo "       sep '\x1f' ts level msg < /var/log/custom.log | where level eq 'err' | pretty"
        return 0
    }
    local esep
    if (( $# == 1 )); then
        # No separator: each whole line is the value of the single field.
        esep=$'\001'
    else
        (($# >= 2)) || { echo "sep: need a separator and at least one field name" >&2; return 1 }
        [[ "$1" != *$'\n'* ]] || { echo "sep: separator may not contain a newline (records are split on lines first)" >&2; return 1 }
        esep=$(printf '%b' "$1") || { echo "sep: bad separator spec: $1" >&2; return 1 }
        [[ -n "$esep" ]] || { echo "sep: separator expands to empty" >&2; return 1 }
    fi

    # Field list with optional ^/* prefixes (only first/^ or last/*).
    local -a fields
    fields=("${@}")
    (( $# >= 2 )) && fields=("${@:2}")
    local -i nf=$(( $# - 1 ))
    local mode="left"
    if [[ "${fields[1]}" == '^'* ]]; then
        mode="right"
        fields[1]="${fields[1]#'^'}"
        [[ "${fields[-1]}" == '*'* ]] || [[ "${fields[-1]}" == '^'* ]] && {
            echo "sep: '^' and '*' prefixes are mutually exclusive" >&2; return 1 }
    elif [[ "${fields[-1]}" == '*'* ]]; then
        # Remainder-on-last-field is the default; the prefix is kept for explicitness.
        fields[-1]="${fields[-1]#'*'}"
    fi
    local j f
    for (( j = 1; j <= nf; ++j )); do
        f="${fields[$j]}"
        [[ "$f" == '^'* || "$f" == '*'* ]] && {
            echo "sep: '$f': prefixes are only allowed on the first (^) or last (*) field" >&2
            return 1
        }
        [[ "$f" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { echo "sep: '$f' is not a valid field name" >&2; return 1 }
    done

    local jqprog='def clean:
        if type == "string" then gsub("\u001b\\[[0-9;]*[a-zA-Z]"; "") else . end;
    def an:
        (clean
        | if (type == "string" and (test("^[+-]?[0-9]+([.][0-9]+)?$"))) then tonumber else . end);
    '
    if [[ "$mode" == "right" ]]; then
        jqprog+='def splitr($s; $k):
        { tail: [], rest: ., need: $k }
        | until ((.need <= 0) or ((.rest | rindex($s)) == null);
            (.rest | rindex($s)) as $i
            | { tail: ([.rest[($i + ($s | length)):]] + .tail),
                rest: .rest[0:$i],
                need: (.need - 1) })
        | { head: .rest,
            tail: (reduce range(0; .need) as $j (.tail; . + [null])) };
    (rtrimstr("\n") | split("\n") | map(select(length > 0)))
    | map(splitr($esep; '"$(( nf - 1 ))"') as $v | {'
        local -i i=0
        for f in "${fields[@]}"; do
            if (( i == 0 )); then
                jqprog+="\"$f\": (\$v.head | an)"
            else
                jqprog+="\"$f\": (\$v.tail[$(( i - 1 ))] | an)"
            fi
            (( ++i < nf )) && jqprog+=", "
        done
    else
        jqprog+='def splitsep($s; $k):
        { parts: [], rest: . }
        | until ((.parts | length) >= $k or (.rest | index($s)) == null;
            (.rest | index($s)) as $i
            | { parts: (.parts + [.rest[0:$i]]),
                rest:  .rest[($i + ($s | length)):] })
        | .parts + [.rest];
    (rtrimstr("\n") | split("\n") | map(select(length > 0)))
    | map(splitsep($esep; '"$(( nf - 1 ))"') as $v | {'
        local -i i=0
        for f in "${fields[@]}"; do
            if (( i == nf - 1 )); then
                jqprog+="\"$f\": ((if (\$v | length) > $i then (\$v[$i:] | join(\$esep)) else null end) | an)"
            else
                jqprog+="\"$f\": (\$v[$i] | an)"
            fi
            (( ++i < nf )) && jqprog+=", "
        done
    fi
    jqprog+=" })"
    jq -Rs --arg esep "$esep" "$jqprog"
}

# Filter a JSON array from stdin by field, operator, and value.
# Multiple field/operator/value triples are AND-combined by default;
# pass --or to keep records matching ANY triple instead.
where() {
    help_check "$1" && {
        echo "Usage: <...> | where [--or] <field> <operator> <value> [<field> <operator> <value> ...]"
        echo "       where --help"
        echo ""
        echo "Keep only the records of a JSON array (from stdin) that match."
        echo "Numeric operators: >, >=, <, <=, ==, != (values are compared as numbers)"
        echo "String operators:  eq, ne, contains (case-insensitive), matches (regex),"
        echo "                   after / before (lexicographic compare — correct for"
        echo "                   ISO-8601 UTC timestamps like journalq's ts)"
        echo "Multiple triples are combined with AND by default; --or keeps"
        echo "records matching ANY triple."
        echo ""
        echo "Example: psq | where mem_percent '>' 1"
        echo "         psq | where --or mem_percent '>' 1 cpu_percent '>' 0"
        echo "         journalq | where --or prio '<=' 4 id eq nginx"
        return 0
    }
    local -a triple_args=("$@")
    local mode="and"
    if [[ "${triple_args[1]}" == "-o" || "${triple_args[1]}" == "--or" ]]; then
        mode="or"
        triple_args=("${triple_args[@]:1}")
    elif [[ "${triple_args[1]}" == "-a" || "${triple_args[1]}" == "--and" ]]; then
        triple_args=("${triple_args[@]:1}")
    fi
    (( (${#triple_args} % 3) == 0 )) || {
        echo "where: arguments must come in <field> <operator> <value> triples (got ${#triple_args})" >&2
        return 1
    }
    local conds_json
    conds_json=$(jq -n --args \
        '$ARGS.positional as $a |
         [ range(0; (($a | length) / 3) | floor) as $i |
           $a[($i * 3):(($i * 3) + 3)] ]' \
        -- "${triple_args[@]}") || return 1
    jq --argjson conds "$conds_json" --arg mode "$mode" '
        def cmp($r; $cond):
            $cond as [$f, $op, $v] |
            if ($op == ">" or $op == ">=" or $op == "<" or $op == "<=" or $op == "==" or $op == "!=")
            then
                ($r[$f] | tonumber?) as $x |
                ($v | tonumber?) as $n |
                if $x == null or $n == null then false
                elif $op == ">" then $x > $n
                elif $op == ">=" then $x >= $n
                elif $op == "<" then $x < $n
                elif $op == "<=" then $x <= $n
                elif $op == "==" then $x == $n
                else $x != $n end
            elif $op == "eq" then ($r[$f] | tostring) == $v
            elif $op == "ne" then ($r[$f] | tostring) != $v
            elif $op == "contains" then ($r[$f] | tostring | ascii_downcase) | contains($v | ascii_downcase)
            elif $op == "matches" then ($r[$f] | tostring) | test($v)
            elif $op == "after" then ($r[$f] | tostring) > $v
            elif $op == "before" then ($r[$f] | tostring) < $v
            else false end;
        map(select(
            . as $r |
            if $mode == "or"
            then any($conds[]; cmp($r; .))
            else all($conds[]; cmp($r; .))
            end))'
}

# Sort a JSON array from stdin by a field.
sort-by() {
    help_check "$1" && {
        echo "Usage: <...> | sort-by <field> [asc|desc]"
        echo "       sort-by --help"
        echo ""
        echo "Sort the records of a JSON array (from stdin) by a field."
        echo "Bare 'sort' is not used so it cannot shadow /usr/bin/sort."
        echo ""
        echo "Example: psq | sort-by mem_percent desc"
        return 0
    }
    local field="$1" dir="${2:-asc}"
    jq --arg f "$field" --arg d "$dir" '
        if $d == "desc" then sort_by(.[$f]) | reverse else sort_by(.[$f]) end'
}

# Keep only the named fields from every record in a JSON array from stdin.
# Bare 'select' is a reserved Zsh word, so the verb is named sel.
sel() {
    help_check "$1" && {
        echo "Usage: <...> | sel <field> [field ...]"
        echo "       sel --help"
        echo ""
        echo "Keep only the named fields from every record of a JSON array (from stdin)."
        echo "Named 'sel' because 'select' is a reserved Zsh word and cannot be defined."
        echo ""
        echo "Example: psq | sel pid mem_percent command"
        return 0
    }
    # Rebuild rows in argument order (record key order from jc is arbitrary).
    jq --args 'map(. as $row |
        reduce $ARGS.positional[] as $f ({}; . + {($f): ($row[$f] // null)}))' "$@"
}

# Keep only the first n records of a JSON array from stdin.
first() {
    help_check "$1" && {
        echo "Usage: <...> | first [n]"
        echo "       first --help"
        echo ""
        echo "Keep only the first n records of a JSON array (from stdin)."
        echo "Defaults to n = 10 when no argument is given."
        return 0
    }
    jq --argjson n "${1:-10}" '.[:$n]'
}

# Keep only the last n records of a JSON array from stdin (companion to first).
last() {
    help_check "$1" && {
        echo "Usage: <...> | last [n]"
        echo "       last --help"
        echo ""
        echo "Keep only the last n records of a JSON array (from stdin)."
        echo "Defaults to n = 10 when no argument is given."
        return 0
    }
    local n="${1:-10}"
    if [[ ! "$n" =~ '^[0-9]+$' ]]; then
        echo "last: '$n' is not a non-negative number." >&2
        return 1
    fi
    if ((n == 0)); then
        # jq's [-0:] would return the whole array; force an empty slice
        jq '[]'
        return 0
    fi
    jq --argjson n "$n" '.[(0 - $n):]'
}

# Pick specific records of a JSON array from stdin by row number, range, or list.
# One-based (row 1 = first record); negative indices count from the end.
row() {
    help_check "$1" && {
        echo "Usage: <...> | row <n> | row <start>:<end> | row <n> <n> ..."
        echo "       row --help"
        echo ""
        echo "Select records from a JSON array (from stdin) by position:"
        echo "    row 5        single record (one-based: 5 = fifth record)"
        echo "    row 5:10     inclusive range, records 5 through 10"
        echo "    row 5 10 15  list of records, in the order given"
        echo "    row -1       negative indices count from the end (-1 = last)"
        echo "Out-of-range indices are silently dropped."
        return 0
    }
    if (($# == 0)); then
        echo "row: at least one row index required (e.g. row 5, row 5:10, row 5 10 15)." >&2
        return 1
    fi
    local -a idxs
    local spec a b i
    for spec in "$@"; do
        if [[ "$spec" =~ '^[+-]?[0-9]+$' ]]; then
            if ((spec == 0)); then
                echo "row: 0 is not a valid row (row numbering is one-based; use row -1 for the last row)." >&2
                return 1
            fi
            # shift positive indices down by one for jq; negatives already
            # count from the end in jq (row -1 == jq .[-1])
            if ((spec > 0)); then
                idxs+=($((spec - 1)))
            else
                idxs+=("$spec")
            fi
        elif [[ "$spec" =~ '^([+-]?[0-9]+):([+-]?[0-9]+)$' ]]; then
            a="${match[1]}"
            b="${match[2]}"
            if ((a <= b)); then
                if ((a <= 0 && b >= 0)); then
                    echo "row: 0 is not a valid row (row numbering is one-based; use row -1 for the last row)." >&2
                    return 1
                fi
                for ((i = a; i <= b; i++)); do
                    if ((i > 0)); then
                        idxs+=($((i - 1)))
                    else
                        idxs+=("$i")
                    fi
                done
            else
                echo "row: invalid range '$spec' (start must be <= end)." >&2
                return 1
            fi
        else
            echo "row: '$spec' is neither a row number nor a range (examples: 5, 5:10, -1)." >&2
            return 1
        fi
    done
    jq --argjson idxs "[${(j:,:)idxs}]" '[.[$idxs[]] | select(. != null)]'
}

# Count the records in a JSON array from stdin.
count() {
    help_check "$1" && {
        echo "Usage: <...> | count"
        echo "       count --help"
        echo ""
        echo "Count the records of a JSON array (from stdin)."
        return 0
    }
    jq 'length'
}

# Print one raw value per line for a field of every record in a JSON array from stdin.
get() {
    help_check "$1" && {
        echo "Usage: <...> | get <field>"
        echo "       get --help"
        echo ""
        echo "Print one raw value per line for <field> of every record of a JSON array (from stdin)."
        echo "Nested objects and arrays are printed as JSON."
        return 0
    }
    jq --arg f "$1" -r '.[] | .[$f] | if type == "object" or type == "array" then tojson else tostring end'
}

# Render a JSON array of objects from stdin as a Nushell-style table:
# rounded borders, right-aligned numeric columns, and cells truncated
# with "..." so the table fits the terminal width. Non-object rows are
# wrapped into a "value" column; empty results print nothing.
pretty() {
    help_check "$1" && {
        echo "Usage: <...> | pretty"
        echo "       pretty --help"
        echo ""
        echo "Render a JSON array of objects from stdin as a Nushell-style table:"
        echo "rounded borders (bold-cyan header, magenta numbers), right-aligned"
        echo "numeric columns, and cells truncated with '...' so the table fits"
        echo "the terminal width."
        echo "With --full, cells are never truncated: columns keep their natural"
        echo "width and lines may extend past the terminal edge."
        return 0
    }
    local maxw="${COLUMNS:-110}"
    if [[ "$*" == *--full* ]]; then
        maxw=1000000
    fi
    jq -r '
        def _rows:
            if type == "object" then [.]                       # single object
            elif type == "array" then map(
                if type == "object" then . else {"value": .} end)
            else [{"value": .}] end;
        def _cell:
            if type == "object" or type == "array" then tojson
            elif type == "null" then ""
            # strip raw ANSI color codes: they occupy bytes but zero display
            # width, which would break the awk column arithmetic
            else (tostring | gsub("\u001b\\[[0-9;]*[a-zA-Z]"; "")) end;

        (_rows) as $rows |
        (reduce ($rows[] | keys_unsorted[]) as $key (
            [];
            . as $acc |
            if ($acc | any(. == $key)) then $acc else $acc + [$key] end
        )) as $cols |
        ($cols | @tsv), ($rows[] | [.[$cols[]] | _cell] | @tsv)
    ' | awk -F '\t' -v maxw="$maxw" '
        # ANSI colors: bold cyan for the header, magenta for numeric cells,
        # strings keep the default color. The escape code is built with
        # sprintf("%c", 27) so the script stays POSIX-awk compatible.
        function rep(c, k,    s, i) { s = ""; for (i = 0; i < k; i++) s = s c; return s }
        function border(l, m, r,    out, i) {
            out = l rep("─", w[1] + 2)
            for (i = 2; i <= n; i++) out = out m rep("─", w[i] + 2)
            return out r
        }
        function cell(s, i, hdr,    t, pad, clr, rst) {
            t = (cut[i] && length(s) > w[i]) ? substr(s, 1, w[i] - 3) "..." : s
            pad = num[i] ? sprintf("%*s", w[i], t) : t rep(" ", w[i] - length(t))
            # color after padding so ANSI bytes never affect column widths
            if (hdr) {
                clr = sprintf("%c[", 27) "1;36m"      # bold cyan
            } else if (t ~ /^[+-]?[0-9]+([.][0-9]+)?$/) {
                clr = sprintf("%c[", 27) "0;35m"      # magenta for numbers
            }
            if (clr != "") {
                rst = sprintf("%c[", 27) "0m"
            }
            return " " clr pad rst " "
        }
        BEGIN { n = 0 }
        n == 0 {
            n = NF
            for (i = 1; i <= n; i++) h[i] = $i
            next
        }
        {
            rows++
            for (i = 1; i <= n; i++) v[rows, i] = (i <= NF ? $i : "")
        }
        END {
            if (n == 0) exit

            # column widths: header or widest cell
            for (i = 1; i <= n; i++) {
                w[i] = length(h[i])
                for (r = 1; r <= rows; r++)
                    if (length(v[r, i]) > w[i]) w[i] = length(v[r, i])
            }

            # numeric columns are right-aligned like Nushell
            for (i = 1; i <= n; i++) {
                num[i] = 1
                for (r = 1; r <= rows; r++)
                    if (v[r, i] != "" && v[r, i] !~ /^[+-]?[0-9]+([.][0-9]+)?$/)
                        { num[i] = 0; break }
            }

            # shrink the widest column(s) until the table fits the terminal
            tw = 1 + n
            for (i = 1; i <= n; i++) tw = tw + w[i] + 2
            while (tw > maxw) {
                big = 1
                for (i = 2; i <= n; i++) if (w[i] > w[big]) big = i
                if (w[big] <= 12) break       # give up, table stays oversized
                w[big]--; cut[big] = 1; tw--
            }

            print border("╭", "┬", "╮")
            out = "│"
            for (i = 1; i <= n; i++) out = out cell(h[i], i, 1) "│"
            print out
            print border("├", "┼", "┤")
            for (r = 1; r <= rows; r++) {
                out = "│"
                for (i = 1; i <= n; i++) out = out cell(v[r, i], i, 0) "│"
                print out
            }
            print border("├", "┼", "┤")
            out = "│"
            for (i = 1; i <= n; i++) out = out cell(h[i], i, 1) "│"
            print out
            print border("╰", "┴", "╯")
        }
    '
}
