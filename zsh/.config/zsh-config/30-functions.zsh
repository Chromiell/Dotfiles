# Reusable shell functions and pager detection.

# Pager selection is shared by the search, man, and fzf helpers.
# Choose batcat, bat, or less as the pager used by search and man-page helpers.
if whence -p batcat >/dev/null 2>&1; then
    _PAGER_PROG=batcat
elif whence -p bat >/dev/null 2>&1; then
    _PAGER_PROG=bat
else
    _PAGER_PROG=less
fi

# File, search, display, and terminal helpers.
# Extract one or more common archive formats.
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

# Search files in the current directory for a text pattern.
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

# Search recursively from the current directory for a text pattern.
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

# Find a filename in the current directory.
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

# Find a filename recursively below the current directory.
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

# Copy a file while showing rsync progress.
cpp() {
    rsync -avh --progress "$1" "$2"
}

# List directories with icons.
ld() {
    if (($#)); then eza -d --group-directories-first --icons=auto "$@"; else eza -D --group-directories-first --icons=auto; fi
}

# List all directories, including hidden ones, with icons.
lad() {
    if (($#)); then eza -ad --group-directories-first --icons=auto "$@"; else eza -aD --group-directories-first --icons=auto; fi
}

# Show a detailed listing of directories with icons.
lld() {
    if (($#)); then eza -alhgd --group-directories-first --icons=auto "$@"; else eza -alhgD --group-directories-first --icons=auto; fi
}

# Show detailed directory listings recursively with icons.
lltd() {
    if (($#)); then eza -alhgTd --group-directories-first --icons=auto "$@"; else eza -alhgTD --group-directories-first --icons=auto; fi
}

# Show detailed directory listings with total sizes.
llld() {
    if (($#)); then eza -alhgd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgD --group-directories-first --total-size --icons=auto; fi
}

# Show recursive directory listings with total sizes.
llltd() {
    if (($#)); then eza -alhgTd --group-directories-first --total-size --icons=auto "$@"; else eza -alhgTD --group-directories-first --total-size --icons=auto; fi
}

# Display manual pages through the selected pager.
man() {
    case "${_PAGER_PROG}" in
        batcat) command man "$@" | col -bx | batcat --language=man --paging=always --style=plain ;;
        bat) command man "$@" | col -bx | bat --language=man --paging=always --style=plain ;;
        *) command man "$@" ;;
    esac
}

# Create a file or stream of random data with the requested size.
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

# Create a tmux session with a randomly generated name.
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
    local name="$1"
    [ -z "$name" ] && name="main"
    tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" || tmux new -n shell -s "$name"
}

# Run a command in a detached tmux session and append its output to a log.
tbg() {
    local name="$1"
    shift
    local logfile="$HOME/tmux-logs/${name}.log"
    mkdir -p "$HOME/tmux-logs"
    tmux new-session -d -s "$name" "{ echo \"[Started at: \$(date)]\"; $@ 2>&1; echo \"[Finished at: \$(date)]\"; } | tee -a \"$logfile\""
    echo -e "Started detached tmux job '$name'\nLogging to: $logfile"
}

# Choose a tmux session with fzf and attach to it.
tsp() {
    local session
    session=$(tmux ls -F '#S' | fzf) || return
    tmux attach -t "$session"
}

# Switch to the most recently used tmux session.
tlast() {
    if [ -n "$TMUX" ]; then tmux switch-client -l 2>/dev/null && return; fi
    local session=$(tmux ls -F "#{session_created} #{session_name}" 2>/dev/null | sort -nr | awk 'NR==1 {print $2}')
    if [ -n "$session" ]; then tmux attach -t "$session"; else echo "No tmux sessions found"; fi
}

# Create a tmux session and log output from all panes.
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

# Provide completion candidates for tmux session names.
_tp_sessions() {
    local -a sessions
    sessions=("${(@f)$(tmux ls -F '#S' 2>/dev/null)}")
    _describe 'tmux sessions' sessions
}

# Print the last requested number of lines from a tmux pane.
tp() {
    local lines="$1" session="$2"
    if [ -z "$lines" ] || [ -z "$session" ]; then
        echo "Usage: tp <num-lines> <session-name>"
        return 1
    fi
    tmux capture-pane -p -t "$session" | tail -n "$lines"
}

# Let Yazi change the current shell directory after navigation.
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

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

# Complete the line count and tmux session arguments for tp.
compdef '_arguments "1: : " "2:tmux session:_tp_sessions"' tp
