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
# for human-readable sizes). Field arguments accept dotted paths into nested
# records (a.b, items.0). Notes on the verb names:
#   - "sort-by" and "uniq-by" are real Nushell verbs (bare "sort"/"uniq"
#     would shadow coreutils), "sel" replaces "select" because select is a
#     Zsh reserved word, and "rename-col" avoids shadowing the Perl rename
#     tool, which also reads stdin.
#   - "where" shadows the Zsh builtin where (command lookup, like which) and
#     "last" shadows /usr/bin/last (login history); both fall back to the
#     original when stdin is a terminal, i.e. when nothing is piped in.
# Producers run their tools through "command" (so aliases such as df='df -h'
# from 40-aliases.zsh never leak in when this file is re-sourced) and under
# LC_ALL=C (so jc always sees English dates and dot decimals).

# jq helpers shared by the verbs. _get resolves a field name or dotted path
# (a literal key containing dots, e.g. from flatten, wins over the path);
# _rows accepts either an array or a single record as input.
typeset -g _NU_JQLIB='
    def _path($f):
        if type == "object" and has($f) then [$f]
        else $f | split(".") | map(if test("^[0-9]+$") then tonumber else . end) end;
    def _get($f): try getpath(_path($f)) catch null;
    def _rows: if type == "array" then . elif type == "null" then [] else [.] end;
    def _objrows: _rows | map(if type == "object" then . else {value: .} end);
    def _str: if . == null then "" elif type == "string" then . else tojson end;
    def _cols: reduce (.[] | keys_unsorted[]) as $k ([]; if any(.[]; . == $k) then . else . + [$k] end);
'

_nu_help() {
    [[ "$1" == "--help" ]]
}

# Fail fast when a verb runs without piped input, instead of silently
# blocking on the terminal while jq waits for JSON.
_nu_stdin() {
    [[ -t 0 ]] || return 0
    echo "$1: expects a JSON array on stdin (e.g. psq | $1 ...)" >&2
    return 1
}

# Running processes as JSON records (pid, user, cpu_percent, mem_percent, command, ...).
psq() {
    _nu_help "$1" && {
        echo "Usage: psq | psq --help"
        echo ""
        echo "Running processes as JSON records via 'ps aux | jc --ps'."
        echo "Fields: pid, user, cpu_percent, mem_percent, vsz, rss, tty, stat, start, time, command"
        return 0
    }
    LC_ALL=C command ps aux | jc --ps
}

# Directory listing as JSON records (filename, flags, size, owner, date, ...).
# -h makes sizes human-readable (K/M/G) instead of raw bytes.
lsq() {
    _nu_help "$1" && {
        echo "Usage: lsq [-h] [path]"
        echo "       lsq --help"
        echo ""
        echo "Directory listing (default: current directory) as JSON records, like"
        echo "'ls -lA': '.' and '..' are omitted, a file path lists just that file,"
        echo "and a symlink to a directory lists the directory's contents."
        echo "Fields: filename, flags, links, owner, group, size, date, link_to (symlinks only)"
        echo "Dates are ISO-like 'YYYY-MM-DD HH:MM' strings, so 'sort-by date'"
        echo "sorts chronologically. Records are sorted by filename."
        echo "With -h, sizes are humanized to K/M/G from the raw byte sizes."
        return 0
    }
    local human=0 target="."
    while (( $# )); do
        case "$1" in
            -h) human=1 ;;
            *)  target="$1" ;;
        esac
        shift
    done
    [[ -e "$target" || -L "$target" ]] || { echo "lsq: cannot access '$target': no such file or directory" >&2; return 1 }
    # find -printf instead of ls | jc --ls: exact dates with the year, and
    # filenames with spaces or newlines survive (fields are NUL-separated).
    local -a depth=(-mindepth 1 -maxdepth 1)
    [[ -d "$target" ]] || depth=(-maxdepth 0)
    LC_ALL=C command find -H "$target" "${depth[@]}" \
        -printf '%f\0%M\0%n\0%u\0%g\0%s\0%TY-%Tm-%Td %TH:%TM\0%l\0' |
        jq -Rs --argjson human "$human" '
            def human:
                if . >= 1073741824 then ((. / 1073741824 * 100) | round / 100 | tostring) + "G"
                elif . >= 1048576 then ((. / 1048576 * 100) | round / 100 | tostring) + "M"
                elif . >= 1024 then ((. / 1024 * 100) | round / 100 | tostring) + "K"
                else tostring end;
            (split("\u0000") | .[:-1]) as $f |
            [range(0; $f | length; 8) as $i | {
                filename: $f[$i],
                flags:    $f[$i + 1],
                links:    ($f[$i + 2] | tonumber),
                owner:    $f[$i + 3],
                group:    $f[$i + 4],
                size:     ($f[$i + 5] | tonumber | if $human == 1 then human else . end),
                date:     $f[$i + 6]
            } + (if $f[$i + 7] == "" then {} else {link_to: $f[$i + 7]} end)]
            | sort_by(.filename)'
}

# Mounted filesystems as JSON records (filesystem, size, used, available, ...).
dfq() {
    _nu_help "$1" && {
        echo "Usage: dfq | dfq --help"
        echo ""
        echo "Mounted filesystems as JSON records via 'df -B1 | jc --df'."
        echo "Fields: filesystem, size, used, available (bytes), use_percent, mounted_on"
        return 0
    }
    # -B1 keeps exact byte counts; rename jc's "1b_blocks" key to "size".
    LC_ALL=C command df -B1 | jc --df |
        jq 'map(with_entries(if .key == "1b_blocks" then .key = "size" else . end))'
}

# Directory tree sizes as JSON records (name, size), one level deep by default.
duq() {
    _nu_help "$1" && {
        echo "Usage: duq [-d <depth> | -a] [path]"
        echo "       duq --help"
        echo ""
        echo "Disk usage as JSON records via 'du -ab -d <depth> <path> | jc --du'."
        echo "Defaults to the current directory, one level deep (its direct"
        echo "entries plus the total for the path itself, like Nushell's du)."
        echo "  -d <depth>  descend <depth> levels (0 = only the path total)"
        echo "  -a, --all   the whole tree, every file (can be very large)"
        echo "Fields: name, size (bytes)"
        echo "Example: duq ~ | sort-by size desc | first 10 | pretty"
        return 0
    }
    local depth=1 target="."
    while (( $# )); do
        case "$1" in
            -d)
                [[ "$2" =~ '^[0-9]+$' ]] || { echo "duq: -d needs a non-negative depth" >&2; return 1 }
                depth="$2"
                shift 2
                ;;
            -a|--all) depth=""; shift ;;
            *)        target="$1"; shift ;;
        esac
    done
    local -a dargs=(-ab)
    [[ -n "$depth" ]] && dargs+=(-d "$depth")
    LC_ALL=C command du "${dargs[@]}" -- "$target" | jc --du
}

# Memory usage as JSON records (type, total, used, free, available, ...).
freeq() {
    _nu_help "$1" && {
        echo "Usage: freeq | freeq --help"
        echo ""
        echo "Memory usage as JSON records via 'free -b | jc --free'."
        echo "Fields: type, total, used, free, shared, buff_cache, available (bytes)"
        return 0
    }
    LC_ALL=C command free -b | jc --free
}

# TCP/UDP sockets as JSON records (netid, state, local_address, local_port, ...).
ssq() {
    _nu_help "$1" && {
        echo "Usage: ssq [-a]"
        echo "       ssq --help"
        echo ""
        echo "TCP and UDP sockets (listening and established) as JSON records via"
        echo "'ss -tuanp | jc --ss'. Ports stay numeric (no service-name lookup)."
        echo "  -a, --all   every socket family, including Unix sockets (ss -anp)"
        echo "Fields: netid, state, recv_q, send_q, local_address, local_port,"
        echo "        local_port_num, peer_address, peer_port, interface, process"
        echo "process is only filled in for your own sockets unless run as root."
        echo "Example: ssq | where state eq LISTEN | sel local_address local_port_num process | pretty"
        return 0
    }
    local -a opts=(-tuanp)
    [[ "$1" == "-a" || "$1" == "--all" ]] && opts=(-anp)
    # stderr is dropped: ss prints harmless netlink warnings on some kernels (WSL)
    LC_ALL=C command ss "${opts[@]}" 2>/dev/null | jc --ss
}

# Current boot journal (or custom journalctl args) as JSON records.
# Use -s/--sudo as the FIRST argument when the journal needs root access.
journalq() {
    _nu_help "$1" && {
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
        echo "Fields: ts (local time, 'YYYY-MM-DDTHH:MM:SS'; empty timestamps fall back to"
        echo "        the epoch), prio (0-7, missing falls back to 6), id, unit, pid, msg"
        echo "Usage:  journalq | where prio '<=' 4 | sort-by ts desc | first 10 | pretty"
        echo "        journalq | where ts after 2026-10-09T13:00 | pretty"
        echo "        journalq -u ssh | where id contains \"sshd\" | pretty"
        echo "        journalq | histogram id | first 10 | pretty"
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
            # ts falls back to the epoch (sorts last on desc), prio to 6 (info).
            # ts is local time so it compares directly with the clock you read.
            ts:   (."__REALTIME_TIMESTAMP" | strv | (tonumber? // 0) / 1000000 | floor
                   | strflocaltime("%Y-%m-%dT%H:%M:%S")),
            prio: (.PRIORITY | strv | tonumber? // 6),
            id:   ((._COMM // .SYSLOG_IDENTIFIER // "?") | strv | ascii_downcase),
            unit: ((._SYSTEMD_UNIT // "") | strv),
            pid:  ((._PID // "") | strv | tonumber? // ""),
            msg:  ((.MESSAGE | strv) | gsub("\n"; " "))
        })'
}

# Run any command through one of jc's parsers ("magic" syntax) and always
# emit a JSON array, so every jc-supported command feeds the verbs.
jcq() {
    _nu_help "$1" && {
        printf '%s\n' \
        "Usage: jcq <command> [args...]" \
        "       jcq --help" \
        "" \
        "Run <command> and parse its output with the matching jc parser" \
        "(jc magic syntax: 'jc <command> [args]'), always emitting a JSON array" \
        "(single-object parsers such as date or uptime are wrapped in [...])." \
        "Supported commands: 'jc --help' lists all parsers (~150)." \
        "" \
        "Example: jcq lsblk | where type eq disk | pretty" \
        "         jcq mount | sel filesystem mount_point type | pretty" \
        "         jcq dig example.com | get answer"
        return 0
    }
    (( $# )) || { echo "jcq: need a command to run (e.g. jcq lsblk)" >&2; return 1 }
    setopt localoptions pipefail
    LC_ALL=C jc "$@" | jq 'if type == "array" then . else [.] end'
}

# Complete jcq's arguments like a fresh command line (as for nohup/sudo).
compdef _precommand jcq

# Split stdin lines into JSON records with a custom separator.
# The separator accepts printf %b escapes, including hex bytes (\t = \x09);
# find raw separators with e.g. 'xxd somelog | head' and pass '\xHH' here.
sep() {
    _nu_help "$1" && {
        echo "Usage: sep [sep] <field>... | sep --help"
        echo ""
        echo "Split each stdin line by <sep> and build JSON records with the given"
        echo "field names in order. Splitting STOPS once every field has a value:"
        echo "any extra separators (e.g. colons inside the text) stay in the"
        echo "last field, so the last field 'absorbs' the remainder."
        echo "With a single argument (no separator), each whole line becomes the"
        echo "value of that one field. Numeric-looking values are auto-converted"
        echo "to numbers, except values with leading zeros (0755, 007), which"
        echo "stay strings. ANSI color escapes in the data are stripped first (so"
        echo "'where' on numbers works with colored output). Blank lines are"
        echo "skipped and Windows CRLF line endings are handled."
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
    local -i nf=${#fields}
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

    # Leading-zero values (0755, 007) stay strings, matching csvq.
    local jqprog='def clean:
        if type == "string" then gsub("\u001b\\[[0-9;]*[a-zA-Z]"; "") else . end;
    def an:
        (clean
        | if (type == "string" and test("^[+-]?[0-9]+([.][0-9]+)?$")
              and (test("^[+-]?0[0-9]") | not)) then tonumber else . end);
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
    (rtrimstr("\n") | split("\n") | map(rtrimstr("\r") | select(length > 0)))
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
    (rtrimstr("\n") | split("\n") | map(rtrimstr("\r") | select(length > 0)))
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

# Read CSV from a file or stdin into JSON records (RFC 4180 via python3 csv).
csvq() {
    _nu_help "$1" && {
        printf '%s\n' \
        "Usage: csvq [file]" \
        "       csvq [-d <char>] [file]" \
        "       csvq --help" \
        "" \
        "Read CSV (first row = header) from <file> or stdin and emit one JSON" \
        "record per data row. RFC 4180 rules: quoted fields, commas inside" \
        "quotes, doubled double-quotes, and multi-line cells are all handled." \
        "A UTF-8 byte-order mark (Excel exports) is ignored." \
        "Values are typed like Nushell's 'from csv': numbers (no leading zero)" \
        "become numbers, true/false become booleans, and empty or missing" \
        "cells become null; extra columns are ignored. This makes" \
        "'<...> | csv | csvq' round-trip types. Only csvq uses python3" \
        "(preinstalled on Debian); csv export is jq-only." \
        "" \
        "  -d <char>   field delimiter (default ','); accepts printf escapes" \
        "              such as '\t', or the word 'tab'" \
        "" \
        "Example: csvq data.csv | where qty '>' 2 | pretty" \
        "         csvq -d tab data.tsv | sel name qty | pretty"
        return 0
    }
    local delim="," src="-"
    while (( $# )); do
        case "$1" in
            -d)
                (( $# >= 2 )) || { echo "csvq: -d needs a delimiter" >&2; return 1 }
                if [[ "$2" == "tab" ]]; then
                    delim=$'\t'
                else
                    delim=$(printf '%b' "$2")
                fi
                shift 2
                ;;
            *)  src="$1"; shift ;;
        esac
    done
    (( ${#delim} == 1 )) || { echo "csvq: delimiter must be a single character" >&2; return 1 }
    [[ "$src" == "-" || -r "$src" ]] || { echo "csvq: cannot read file: $src" >&2; return 1 }
    local pyprog='import csv, io, json, re, sys
delim, src = sys.argv[1], sys.argv[2]
# utf-8-sig drops an Excel BOM; newline="" is required by the csv module
# for quoted multi-line cells.
if src == "-":
    fh = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8-sig", newline="")
else:
    fh = open(src, encoding="utf-8-sig", newline="")
reader = csv.reader(fh, delimiter=delim)
try:
    header = next(reader)
except StopIteration:
    print("[]")
    raise SystemExit
numeric = re.compile(r"^[+-]?[0-9]+([.][0-9]+)?$")
leading_zero = re.compile(r"^[+-]?0[0-9]")
def typed(v):
    if v is None or v == "":
        return None
    if numeric.match(v) and not leading_zero.match(v):
        return float(v) if "." in v else int(v)
    if v in ("true", "false"):
        return v == "true"
    return v
out = []
for row in reader:
    if not row:
        continue
    out.append({key: typed(row[i] if i < len(row) else None)
                for i, key in enumerate(header)})
print(json.dumps(out))'
    python3 -c "$pyprog" "$delim" "$src"
}

# Filter a JSON array from stdin by field, operator, and value.
# Multiple field/operator/value triples are AND-combined by default;
# pass --or to keep records matching ANY triple instead.
where() {
    _nu_help "$1" && {
        echo "Usage: <...> | where [--or] <field> <operator> <value> [<field> <operator> <value> ...]"
        echo "       where --help"
        echo ""
        echo "Keep only the records of a JSON array (from stdin) that match."
        echo "Numeric:  >, >=, <, <=, ==, != (both sides compared as numbers;"
        echo "          records whose field is not numeric never match)"
        echo "String:   eq, ne         equality (numeric fields compare as numbers)"
        echo "          contains, not-contains   substring, case-insensitive"
        echo "          starts-with, ends-with   prefix / suffix, case-sensitive"
        echo "          matches, '!~'             regex match / no match"
        echo "          in, not-in     value is one of a comma-separated list"
        echo "          after, before  lexicographic compare (correct for ISO-8601"
        echo "                         timestamps like journalq's ts or lsq's date)"
        echo "Missing/null fields compare as the empty string for string operators."
        echo "<field> may be a dotted path into nested records (e.g. a.b)."
        echo "Multiple triples are combined with AND by default; --or keeps"
        echo "records matching ANY triple."
        echo "Without piped input, the Zsh builtin 'where' (command lookup) runs instead."
        echo ""
        echo "Example: psq | where mem_percent '>' 1"
        echo "         psq | where --or mem_percent '>' 1 cpu_percent '>' 0"
        echo "         journalq | where --or prio '<=' 4 id eq nginx"
        echo "         lsq | where filename ends-with .zsh"
        echo "         psq | where user in root,www-data"
        return 0
    }
    if [[ -t 0 ]]; then
        builtin where "$@"
        return
    fi
    local -a triple_args=("$@")
    local mode="and"
    if [[ "${triple_args[1]}" == "-o" || "${triple_args[1]}" == "--or" ]]; then
        mode="or"
        triple_args=("${triple_args[@]:1}")
    elif [[ "${triple_args[1]}" == "-a" || "${triple_args[1]}" == "--and" ]]; then
        triple_args=("${triple_args[@]:1}")
    fi
    (( ${#triple_args} > 0 && (${#triple_args} % 3) == 0 )) || {
        echo "where: arguments must come in <field> <operator> <value> triples (got ${#triple_args})" >&2
        return 1
    }
    local -i k
    local op
    for (( k = 2; k <= ${#triple_args}; k += 3 )); do
        op="${triple_args[$k]}"
        case "$op" in
            '>'|'>='|'<'|'<='|'=='|'!='|eq|ne|contains|not-contains|starts-with|ends-with|matches|'!~'|in|not-in|after|before) ;;
            *) echo "where: unknown operator '$op' (see where --help)" >&2; return 1 ;;
        esac
    done
    local conds_json
    conds_json=$(jq -n --args \
        '$ARGS.positional as $a |
         [ range(0; (($a | length) / 3) | floor) as $i |
           $a[($i * 3):(($i * 3) + 3)] ]' \
        -- "${triple_args[@]}") || return 1
    jq --argjson conds "$conds_json" --arg mode "$mode" "$_NU_JQLIB"'
        def cmp($r; $cond):
            $cond as [$f, $op, $v] |
            ($r | _get($f)) as $x |
            if ($op == ">" or $op == ">=" or $op == "<" or $op == "<=" or $op == "==" or $op == "!=")
            then
                ($x | (tonumber? // null)) as $xn |
                ($v | (tonumber? // null)) as $n |
                if $xn == null or $n == null then false
                elif $op == ">" then $xn > $n
                elif $op == ">=" then $xn >= $n
                elif $op == "<" then $xn < $n
                elif $op == "<=" then $xn <= $n
                elif $op == "==" then $xn == $n
                else $xn != $n end
            elif $op == "eq" or $op == "ne" then
                (if ($x | type) == "number" and ($v | tonumber? // null) != null
                 then $x == ($v | tonumber)
                 else ($x | _str) == $v end) as $same |
                if $op == "eq" then $same else ($same | not) end
            elif $op == "contains" then ($x | _str | ascii_downcase) | contains($v | ascii_downcase)
            elif $op == "not-contains" then ($x | _str | ascii_downcase) | contains($v | ascii_downcase) | not
            elif $op == "starts-with" then ($x | _str) | startswith($v)
            elif $op == "ends-with" then ($x | _str) | endswith($v)
            elif $op == "matches" then ($x | _str) | test($v)
            elif $op == "!~" then ($x | _str) | test($v) | not
            elif $op == "in" then ($x | _str) as $s | any($v | split(",")[]; . == $s)
            elif $op == "not-in" then ($x | _str) as $s | any($v | split(",")[]; . == $s) | not
            elif $op == "after" then ($x | _str) > $v
            elif $op == "before" then ($x | _str) < $v
            else false end;
        _rows | map(select(
            . as $r |
            if $mode == "or"
            then any($conds[]; cmp($r; .))
            else all($conds[]; cmp($r; .))
            end))'
}

# Sort a JSON array from stdin by one or more fields.
sort-by() {
    _nu_help "$1" && {
        echo "Usage: <...> | sort-by <field> [asc|desc] [<field> [asc|desc] ...]"
        echo "       sort-by --help"
        echo ""
        echo "Sort the records of a JSON array (from stdin) by one or more fields;"
        echo "later fields break ties of earlier ones. Each field may be followed"
        echo "by its own direction (asc by default, case-insensitive). The sort is"
        echo "stable. Types order as null < false < true < numbers < strings."
        echo "Bare 'sort' is not used so it cannot shadow /usr/bin/sort."
        echo ""
        echo "Example: psq | sort-by mem_percent desc"
        echo "         psq | sort-by user cpu_percent desc"
        return 0
    }
    _nu_stdin sort-by || return 1
    local -a pairs
    local arg
    for arg in "$@"; do
        case "${arg:l}" in
            asc|desc)
                (( ${#pairs} )) || { echo "sort-by: '$arg' must follow a field name" >&2; return 1 }
                pairs[-1]="${arg:l}"
                ;;
            *) pairs+=("$arg" asc) ;;
        esac
    done
    (( ${#pairs} )) || { echo "sort-by: need at least one field (see sort-by --help)" >&2; return 1 }
    # Apply the keys from last to first; group_by is a stable sort, and
    # reversing whole groups (not records) keeps desc stable too.
    jq --args "$_NU_JQLIB"'
        ($ARGS.positional as $a |
         [range(0; $a | length; 2) as $i | {f: $a[$i], desc: ($a[$i + 1] == "desc")}]) as $keys |
        _rows | reduce ($keys | reverse)[] as $k (.;
            if $k.desc then [group_by(_get($k.f)) | reverse | .[][]]
            else [group_by(_get($k.f)) | .[][]] end)' -- "${pairs[@]}"
}

# Keep only the named fields from every record in a JSON array from stdin.
# Bare 'select' is a reserved Zsh word, so the verb is named sel.
sel() {
    _nu_help "$1" && {
        echo "Usage: <...> | sel <field> [field ...]"
        echo "       sel --help"
        echo ""
        echo "Keep only the named fields from every record of a JSON array (from stdin),"
        echo "in the order given. Dotted paths (a.b) pick nested values into a column"
        echo "named after the path. Missing fields become null."
        echo "Named 'sel' because 'select' is a reserved Zsh word and cannot be defined."
        echo ""
        echo "Example: psq | sel pid mem_percent command"
        return 0
    }
    _nu_stdin sel || return 1
    (( $# )) || { echo "sel: need at least one field name" >&2; return 1 }
    # Rebuild rows in argument order (record key order from jc is arbitrary).
    jq --args "$_NU_JQLIB"'_objrows | map(. as $row |
        reduce $ARGS.positional[] as $f ({}; . + {($f): ($row | _get($f))}))' -- "$@"
}

# Drop the named fields from every record in a JSON array from stdin (inverse of sel).
reject() {
    _nu_help "$1" && {
        echo "Usage: <...> | reject <field> [field ...]"
        echo "       reject --help"
        echo ""
        echo "Remove the named fields from every record of a JSON array (from stdin);"
        echo "the opposite of sel. Dotted paths (a.b) remove nested values."
        echo ""
        echo "Example: psq | reject vsz rss tty stat | pretty"
        return 0
    }
    _nu_stdin reject || return 1
    (( $# )) || { echo "reject: need at least one field name" >&2; return 1 }
    jq --args "$_NU_JQLIB"'_rows | map(
        reduce $ARGS.positional[] as $f (.; try delpaths([_path($f)]) catch .))' -- "$@"
}

# Rename columns of every record in a JSON array from stdin (Nushell "rename";
# a different name so it never shadows the Perl rename tool).
rename-col() {
    _nu_help "$1" && {
        echo "Usage: <...> | rename-col <old> <new> [<old> <new> ...]"
        echo "       rename-col --help"
        echo ""
        echo "Rename top-level fields of every record of a JSON array (from stdin),"
        echo "keeping column order. Records without <old> are left unchanged."
        echo "Named 'rename-col' so it cannot shadow the Perl 'rename' tool."
        echo ""
        echo "Example: psq | sel pid mem_percent | rename-col mem_percent mem | pretty"
        return 0
    }
    _nu_stdin rename-col || return 1
    (( $# > 0 && $# % 2 == 0 )) || { echo "rename-col: arguments must come in <old> <new> pairs" >&2; return 1 }
    jq --args "$_NU_JQLIB"'
        ($ARGS.positional as $a |
         reduce range(0; $a | length; 2) as $i ({}; .[$a[$i]] = $a[$i + 1])) as $map |
        _rows | map(if type == "object"
            then with_entries(.key = ($map[.key] // .key))
            else . end)' -- "$@"
}

# Replace (or add) a field in every record with the result of a jq expression.
update() {
    _nu_help "$1" && {
        printf '%s\n' \
        "Usage: <...> | update <field> <jq-expression>" \
        "       update --help" \
        "" \
        "Set <field> of every record of a JSON array (from stdin) to the result of" \
        "<jq-expression>. Inside the expression '.' is the current field value" \
        "(null when missing, so update also adds new fields) and '\$row' is the" \
        "whole record. <field> may be a dotted path (a.b)." \
        "" \
        "Example: psq | update command 'split(\" \")[0]' | pretty" \
        "         dfq | update size '. / 1073741824 | floor' | pretty" \
        "         psq | update owner_pid '\$row.user + \":\" + (\$row.pid | tostring)' | pretty"
        return 0
    }
    _nu_stdin update || return 1
    (( $# == 2 )) || { echo "update: need a field and a jq expression (see update --help)" >&2; return 1 }
    jq --arg f "$1" "$_NU_JQLIB"'_rows | map(. as $row | _path($f) as $p |
        setpath($p; (try getpath($p) catch null) | ('"$2"')))'
}

# Keep only the first n records of a JSON array from stdin.
first() {
    _nu_help "$1" && {
        echo "Usage: <...> | first [n]"
        echo "       first --help"
        echo ""
        echo "Keep only the first n records of a JSON array (from stdin)."
        echo "Defaults to n = 10 when no argument is given."
        return 0
    }
    _nu_stdin first || return 1
    local n="${1:-10}"
    if [[ ! "$n" =~ '^[0-9]+$' ]]; then
        echo "first: '$n' is not a non-negative number." >&2
        return 1
    fi
    jq --argjson n "$n" "$_NU_JQLIB"'_rows | .[:$n]'
}

# Keep only the last n records of a JSON array from stdin (companion to first).
# With nothing piped in, runs the real last(1) (login history) when installed.
last() {
    _nu_help "$1" && {
        echo "Usage: <...> | last [n]"
        echo "       last --help"
        echo ""
        echo "Keep only the last n records of a JSON array (from stdin)."
        echo "Defaults to n = 10 when no argument is given."
        echo "Without piped input, /usr/bin/last (login history) runs instead when"
        echo "installed ('command last --help' shows its own help)."
        return 0
    }
    if [[ -t 0 ]] && (( $+commands[last] )); then
        command last "$@"
        return
    fi
    _nu_stdin last || return 1
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
    jq --argjson n "$n" "$_NU_JQLIB"'_rows | .[(0 - $n):]'
}

# Drop the first n records of a JSON array from stdin.
skip() {
    _nu_help "$1" && {
        echo "Usage: <...> | skip [n]"
        echo "       skip --help"
        echo ""
        echo "Drop the first n records of a JSON array (from stdin) and keep the rest."
        echo "Defaults to n = 1 (e.g. to drop a header-like first record)."
        echo ""
        echo "Example: psq | sort-by mem_percent desc | skip 10 | first 10 | pretty"
        return 0
    }
    _nu_stdin skip || return 1
    local n="${1:-1}"
    if [[ ! "$n" =~ '^[0-9]+$' ]]; then
        echo "skip: '$n' is not a non-negative number." >&2
        return 1
    fi
    jq --argjson n "$n" "$_NU_JQLIB"'_rows | .[$n:]'
}

# Reverse the order of the records of a JSON array from stdin.
reverse() {
    _nu_help "$1" && {
        echo "Usage: <...> | reverse"
        echo "       reverse --help"
        echo ""
        echo "Reverse the order of the records of a JSON array (from stdin)."
        return 0
    }
    _nu_stdin reverse || return 1
    jq "$_NU_JQLIB"'_rows | reverse'
}

# Pick specific records of a JSON array from stdin by row number, range, or list.
# One-based (row 1 = first record); negative indices count from the end.
row() {
    _nu_help "$1" && {
        echo "Usage: <...> | row <n> | row <start>:<end> | row <n> <n> ..."
        echo "       row --help"
        echo ""
        echo "Select records from a JSON array (from stdin) by position:"
        echo "    row 5        single record (one-based: 5 = fifth record)"
        echo "    row 5:10     inclusive range, records 5 through 10"
        echo "    row 5 10 15  list of records, in the order given"
        echo "    row -1       negative indices count from the end (-1 = last)"
        echo "Out-of-range indices are silently dropped."
        echo "Row numbers match the '#' column printed by pretty."
        return 0
    }
    _nu_stdin row || return 1
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
    jq --argjson idxs "[${(j:,:)idxs}]" "$_NU_JQLIB"'_rows | [.[$idxs[]] | select(. != null)]'
}

# Drop duplicate records (or records with duplicate field values) from stdin.
uniq-by() {
    _nu_help "$1" && {
        echo "Usage: <...> | uniq-by [field ...]"
        echo "       uniq-by --help"
        echo ""
        echo "Keep the first record for each distinct combination of the given"
        echo "fields of a JSON array (from stdin); with no fields, drop exact"
        echo "duplicate records. Input order is preserved."
        echo "Bare 'uniq' is not used so it cannot shadow /usr/bin/uniq."
        echo ""
        echo "Example: psq | uniq-by user | sel user command | pretty"
        return 0
    }
    _nu_stdin uniq-by || return 1
    jq --args "$_NU_JQLIB"'
        _rows | reduce .[] as $r ({seen: {}, out: []};
            ($r | if ($ARGS.positional | length) == 0 then tojson
                  else [$ARGS.positional[] as $f | _get($f)] | tojson end) as $key |
            if .seen[$key] then . else .seen[$key] = true | .out += [$r] end)
        | .out' -- "$@"
}

# Group the records of a JSON array from stdin by a field value.
group-by() {
    _nu_help "$1" && {
        echo "Usage: <...> | group-by <field>"
        echo "       group-by --help"
        echo ""
        echo "Group the records of a JSON array (from stdin) by the value of <field>."
        echo "Emits one record per distinct value, sorted by that value:"
        echo "    {<field>: value, count: n, items: [records...]}"
        echo "Pipe into 'reject items' for a compact overview, or into"
        echo "'where <field> eq X | get items' to drill into one group."
        echo ""
        echo "Example: psq | group-by user | reject items | pretty"
        return 0
    }
    _nu_stdin group-by || return 1
    (( $# == 1 )) || { echo "group-by: need exactly one field" >&2; return 1 }
    jq --arg f "$1" "$_NU_JQLIB"'_rows | group_by(_get($f))
        | map({($f): (.[0] | _get($f)), count: length, items: .})'
}

# Count how often each value of a field occurs in a JSON array from stdin.
histogram() {
    _nu_help "$1" && {
        echo "Usage: <...> | histogram <field>"
        echo "       histogram --help"
        echo ""
        echo "Count the distinct values of <field> in a JSON array (from stdin):"
        echo "    {<field>: value, count: n, percent: share of all records}"
        echo "sorted by count, most frequent first. Replaces the classic"
        echo "'get <field> | sort | uniq -c | sort -rn'."
        echo ""
        echo "Example: journalq | histogram id | first 10 | pretty"
        return 0
    }
    _nu_stdin histogram || return 1
    (( $# == 1 )) || { echo "histogram: need exactly one field" >&2; return 1 }
    jq --arg f "$1" "$_NU_JQLIB"'_rows | length as $n | group_by(_get($f))
        | map({($f): (.[0] | _get($f)), count: length,
               percent: ((length * 10000 / $n | round) / 100)})
        | sort_by(-.count)'
}

# Aggregate a numeric field of a JSON array from stdin (sum, avg, min, max, median).
math() {
    _nu_help "$1" && {
        echo "Usage: <...> | math <sum|avg|min|max|median> [field]"
        echo "       math --help"
        echo ""
        echo "Aggregate the numeric values of <field> over a JSON array (from stdin)"
        echo "and print one raw number. Without a field, the array elements"
        echo "themselves are used. Numeric strings count; non-numeric and missing"
        echo "values are ignored. avg/min/max/median of nothing print null."
        echo ""
        echo "Example: psq | math sum mem_percent"
        echo "         duq | where name ne . | math max size"
        return 0
    }
    _nu_stdin math || return 1
    case "$1" in
        sum|avg|min|max|median) ;;
        *) echo "math: unknown operation '$1' (sum, avg, min, max, median)" >&2; return 1 ;;
    esac
    jq --arg op "$1" --arg f "${2:-}" "$_NU_JQLIB"'
        [_rows[] | (if $f == "" then . else _get($f) end) | tonumber?] as $v |
        if $op == "sum" then ($v | add // 0)
        elif ($v | length) == 0 then null
        elif $op == "avg" then ($v | add / length)
        elif $op == "min" then ($v | min)
        elif $op == "max" then ($v | max)
        else ($v | sort | length as $l |
              if $l % 2 == 1 then .[($l - 1) / 2]
              else (.[$l / 2 - 1] + .[$l / 2]) / 2 end)
        end'
}

# Count the records in a JSON array from stdin.
count() {
    _nu_help "$1" && {
        echo "Usage: <...> | count"
        echo "       count --help"
        echo ""
        echo "Count the records of a JSON array (from stdin)."
        return 0
    }
    _nu_stdin count || return 1
    jq "$_NU_JQLIB"'_rows | length'
}

# Print one raw value per line for a field of every record in a JSON array from stdin.
get() {
    _nu_help "$1" && {
        echo "Usage: <...> | get <field>"
        echo "       get --help"
        echo ""
        echo "Print one raw value per line for <field> of every record of a JSON array"
        echo "(from stdin). <field> may be a dotted path (a.b). Nested objects and"
        echo "arrays are printed as JSON."
        return 0
    }
    _nu_stdin get || return 1
    (( $# == 1 )) || { echo "get: need exactly one field" >&2; return 1 }
    jq --arg f "$1" -r "$_NU_JQLIB"'_rows[] | _get($f)
        | if type == "object" or type == "array" then tojson else tostring end'
}

# Flatten nested records into dotted top-level columns (a.b, a.c).
flatten() {
    _nu_help "$1" && {
        echo "Usage: <...> | flatten"
        echo "       flatten --help"
        echo ""
        echo "Turn nested records into top-level columns with dotted names, e.g."
        echo "{\"a\": {\"b\": 1}} becomes {\"a.b\": 1}. Arrays are kept as values."
        echo "Verbs still find the columns by their dotted names afterwards."
        echo ""
        echo "Example: jcq lsblk | flatten | pretty"
        return 0
    }
    _nu_stdin flatten || return 1
    jq "$_NU_JQLIB"'
        def _flat($pre):
            to_entries
            | map(if (.value | type) == "object" and (.value | length) > 0
                  then .key as $k | .value | _flat($pre + $k + ".")
                  else {($pre + .key): .value} end)
            | add // {};
        _rows | map(if type == "object" then _flat("") else . end)'
}

# Turn a nested list (or record) field into its own table: one row per item.
# Named "unnest" (SQL UNNEST) because /usr/bin/expand is a coreutils tool.
unnest() {
    _nu_help "$1" && {
        echo "Usage: <...> | unnest [-k | --keep] <field>"
        echo "       unnest --help"
        echo ""
        echo "Replace the records of a JSON array (from stdin) with the contents of"
        echo "<field>: every item of a list field becomes its own row (a record field"
        echo "becomes one row). Records where <field> is missing or null are skipped."
        echo "<field> may be a dotted path (a.b)."
        echo "  -k, --keep   also carry the parent record's other columns onto each"
        echo "               row (item fields win on name clashes; non-record items"
        echo "               stay under the <field> column)"
        echo ""
        echo "Example: jcq id | unnest groups | pretty"
        echo "         jcq dig example.com | unnest answer | sel name type data | pretty"
        echo "         ip -j addr | unnest --keep addr_info | sel ifname family local prefixlen | pretty"
        return 0
    }
    _nu_stdin unnest || return 1
    local keep=0
    if [[ "$1" == "-k" || "$1" == "--keep" ]]; then
        keep=1
        shift
    fi
    (( $# == 1 )) || { echo "unnest: need exactly one field (see unnest --help)" >&2; return 1 }
    jq --arg f "$1" --argjson keep "$keep" "$_NU_JQLIB"'
        [_rows[] | . as $row | _get($f) as $v | select($v != null)
         | ($v | if type == "array" then .[] else . end) as $item
         | if $keep == 1 and ($row | type) == "object" then
               ($row | try delpaths([_path($f)]) catch .) as $base
               | if ($item | type) == "object" then $base + $item
                 else $base + {($f): $item} end
           else $item end]'
}

# Swap rows and columns of a JSON array from stdin (one record becomes a key/value table).
transpose() {
    _nu_help "$1" && {
        echo "Usage: <...> | transpose"
        echo "       transpose --help"
        echo ""
        echo "Swap rows and columns of a JSON array (from stdin). A single record"
        echo "becomes {column, value} rows; several records become one row per"
        echo "column, with the values in columns named 1, 2, ... (row numbers)."
        echo ""
        echo "Example: psq | row 1 | transpose | pretty"
        return 0
    }
    _nu_stdin transpose || return 1
    jq "$_NU_JQLIB"'
        _objrows | . as $rs |
        if length == 1 then (.[0] | to_entries | map({column: .key, value: .value}))
        else [_cols[] as $c | {column: $c} +
              ([range(0; $rs | length) as $i | {(($i + 1) | tostring): $rs[$i][$c]}] | add // {})]
        end'
}

# Export records from stdin to RFC 4180 CSV (header row + data rows).
csv() {
    _nu_help "$1" && {
        printf '%s\n' \
        "Usage: <...> | csv" \
        "       csv --help" \
        "" \
        "Export a JSON array of records (from stdin) as RFC 4180 CSV: a header" \
        "row using the union of keys (first-seen order), then one data row per" \
        "record. Missing fields and nulls become empty cells; nested" \
        "objects/arrays are serialized as JSON inside their cell; cells with" \
        "commas, quotes, or newlines are quoted. Import back with csvq." \
        "" \
        "Example: psq | sel pid mem_percent command | csv > ps.csv" \
        return 0
    }
    _nu_stdin csv || return 1
    jq -r "$_NU_JQLIB"'
        _objrows | _cols as $cols |
        ($cols | @csv),
        (.[] | [.[$cols[]] |
            if type == "object" or type == "array" then (tojson)
            else . end] | @csv)
    '
}

# Render a JSON array of objects from stdin as a Nushell-style table:
# rounded borders, a "#" row-number column, right-aligned numeric columns,
# and cells truncated with "..." so the table fits the terminal width.
# Widths are measured in terminal columns (CJK and emoji count double).
pretty() {
    _nu_help "$1" && {
        echo "Usage: <...> | pretty [--full] [--no-index] [--color <when>]"
        echo "       pretty --help"
        echo ""
        echo "Render a JSON array of objects from stdin as a Nushell-style table:"
        echo "rounded borders (bold-cyan header, green row numbers, magenta numbers),"
        echo "right-aligned numeric columns, and cells truncated with '...' so the"
        echo "table fits the terminal width. The header repeats at the bottom only"
        echo "when the table is taller than the terminal. A single record (not an"
        echo "array) renders as a vertical column/value table. Non-object rows go"
        echo "into a 'value' column; an empty array prints an 'empty list' box."
        echo "  --full       never truncate cells (lines may pass the terminal edge)"
        echo "  --no-index   hide the '#' row-number column"
        echo "  --color <when>  when to use colors, like ripgrep (also --color=<when>):"
        echo "                    auto    colors only when stdout is a terminal and"
        echo "                            NO_COLOR is unset (default)"
        echo "                    always  always emit colors (e.g. | less -R)"
        echo "                    ansi    same as always"
        echo "                    never   never emit colors"
        echo "                  When given more than once, the last one wins."
        return 0
    }
    _nu_stdin pretty || return 1
    local full=0 index=1 when=auto
    while (( $# )); do
        case "$1" in
            --full)     full=1 ;;
            --no-index) index=0 ;;
            --color=*)  when="${1#--color=}" ;;
            --color)
                (( $# >= 2 )) || { echo "pretty: --color needs a value (never, auto, always, ansi)" >&2; return 1 }
                when="$2"
                shift
                ;;
            *) echo "pretty: unknown option '$1' (see pretty --help)" >&2; return 1 ;;
        esac
        shift
    done
    local -i color
    case "$when" in
        never)         color=0 ;;
        always|ansi)   color=1 ;;
        auto)          [[ -t 1 && -z "${NO_COLOR-}" ]] && color=1 || color=0 ;;
        *) echo "pretty: invalid --color value '$when' (never, auto, always, ansi)" >&2; return 1 ;;
    esac
    local maxw="${COLUMNS:-110}" lines="${LINES:-0}"
    # COLUMNS is 0 or garbage when no terminal is attached
    [[ "$maxw" =~ '^[0-9]+$' ]] && (( maxw > 0 )) || maxw=110
    [[ "$lines" =~ '^[0-9]+$' ]] || lines=0
    jq -r --argjson maxw "$maxw" --argjson lines "$lines" --argjson full "$full" \
        --argjson index "$index" --argjson color "$color" "$_NU_JQLIB"'
        # display width of one code point (wcwidth approximation: combining
        # marks are 0 columns, East Asian wide characters and emoji are 2)
        def _cw:
            if . < 32 or (. >= 768 and . <= 879) or (. >= 8203 and . <= 8207)
               or (. >= 65024 and . <= 65039) then 0
            elif . >= 4352 and (. <= 4447 or . == 9001 or . == 9002
               or (. >= 11904 and . <= 42191 and . != 12351)
               or (. >= 44032 and . <= 55203) or (. >= 63744 and . <= 64255)
               or (. >= 65040 and . <= 65049) or (. >= 65072 and . <= 65135)
               or (. >= 65280 and . <= 65376) or (. >= 65504 and . <= 65510)
               or (. >= 127744 and . <= 129791) or (. >= 131072 and . <= 262141)) then 2
            else 1 end;
        def _w: [explode[] | _cw] | add // 0;
        def _rep($s; $n): reduce range(0; $n) as $_ (""; . + $s);
        def _trunc($w):
            if _w <= $w then .
            else (reduce explode[] as $c ({s: [], n: 0, done: false};
                    if .done then .
                    else ($c | _cw) as $k
                    | if .n + $k > $w - 3 then .done = true
                      else .s += [$c] | .n += $k end end)
                  | .s | implode) + "..." end;
        def _pad($w; $right):
            ($w - _w) as $p |
            if $p <= 0 then . elif $right then _rep(" "; $p) + . else . + _rep(" "; $p) end;
        def _isnum: test("^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$");
        def _paint($code): if $color == 1 then "\u001b[" + $code + "m" + . + "\u001b[0m" else . end;
        # raw ANSI codes and control characters would break the width math
        def _cell:
            if type == "object" or type == "array" then tojson
            elif type == "null" then ""
            else tostring | gsub("\u001b\\[[0-9;]*[a-zA-Z]"; "")
                 | gsub("\r?\n"; "↵") | gsub("[\t\u0000-\u001f]"; " ") end;
        def _line($cells; $hdr; $w; $num; $idx):
            "│" + ([range(0; $w | length) as $i |
                ($cells[$i] | _trunc($w[$i]) | _pad($w[$i]; $num[$i])) as $t |
                " " + (if $hdr then ($t | _paint("1;36"))
                       elif $i < $idx then ($t | _paint("1;32"))
                       elif ($cells[$i] | _isnum) then ($t | _paint("0;35"))
                       else $t end) + " "] | join("│")) + "│";

        (type == "object") as $record |
        (if $record then [to_entries[] | {column: .key, value: .value}] else _objrows end) as $rows |
        (if $record then 0 else $index end) as $idx |
        if ($rows | length) == 0 then
            ("╭────────────╮", "│ empty list │", "╰────────────╯")
        else
            ($rows | _cols) as $cols |
            ([$rows[] | [.[$cols[]] | _cell]]) as $data |
            (if $idx == 1 then ["#"] + $cols else $cols end) as $hdr |
            (if $idx == 1
             then [range(0; $data | length) as $r | [($r + 1) | tostring] + $data[$r]]
             else $data end) as $body |
            ($hdr | length) as $n |
            [range(0; $n) as $i | [$hdr[$i], ($body[] | .[$i])] | map(_w) | max] as $w0 |
            [range(0; $n) as $i | all($body[] | .[$i]; . == "" or _isnum)] as $num |
            # shrink the widest column(s) until the table fits the terminal;
            # columns are never cut below 12 (the table stays oversized then)
            (if $full == 1 then $w0
             else {w: $w0, tw: (1 + $n * 3 + ($w0 | add))}
                | until(.tw <= $maxw or (.w | max) <= 12;
                    (.w | max) as $m |
                    (.w | index($m)) as $b |
                    ([.w | to_entries[] | select(.key != $b) | .value] | max // 0) as $second |
                    ([1, ([.tw - $maxw, $m - ([$second, 12] | max)] | min)] | max) as $d |
                    .w[$b] -= $d | .tw -= $d)
                | .w end) as $w |
            ([$w[] as $x | _rep("─"; $x + 2)]) as $seg |
            ("╭" + ($seg | join("┬")) + "╮"),
            _line($hdr; true; $w; $num; $idx),
            ("├" + ($seg | join("┼")) + "┤"),
            ($body[] | _line(.; false; $w; $num; $idx)),
            (if $lines > 0 and ($body | length) + 4 > $lines
             then ("├" + ($seg | join("┼")) + "┤"), _line($hdr; true; $w; $num; $idx)
             else empty end),
            ("╰" + ($seg | join("┴")) + "╯")
        end'
}
