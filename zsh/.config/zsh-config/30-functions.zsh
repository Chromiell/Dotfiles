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
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: extract <archive> [archive ...]"
        echo "       extract -h | --help"
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
        echo "       compress -h | --help"
        echo ""
        echo "Compress target file(s) or directory(ies) into an archive."
        echo "Supports: .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .tar, .zip, .7z, .rar, .gz, .bz2"
        return 0
    fi

    local archive="$1"
    shift  # Remove the archive name from the argument list

    # Check that all remaining source files/directories exist
    for source in "$@"; do
        if [[ ! -e "$source" ]]; then
            echo "'$source' does not exist!"
            return 1
        fi
    done

    case "$archive" in
        *.tar.gz|*.tgz)   tar czvf "$archive" "$@" ;;
        *.tar.bz2|*.tbz2) tar cjvf "$archive" "$@" ;;
        *.tar.xz)         tar cJvf "$archive" "$@" ;;
        *.tar)            tar cvf  "$archive" "$@" ;;
        *.zip)            zip -r   "$archive" "$@" ;;
        *.7z)             7z a     "$archive" "$@" ;;
        *.rar)            rar a    "$archive" "$@" ;;
        *.gz)
            if [[ $# -gt 1 || -d "$1" ]]; then
                echo "Error: .gz can only compress a single file directly. Use .tar.gz for multiple files or directories."
                return 1
            fi
            gzip -k "$1"  # -k keeps original file
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

# Search files in the current directory for a text pattern.
ftext() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: ftext [options] <pattern> [file]"
        echo "       ftext -h | --help"
        echo ""
        echo "Search files in the current directory for a text pattern."
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
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: frtext [options] <pattern>"
        echo "       frtext -h | --help"
        echo ""
        echo "Search recursively from the current directory for a text pattern."
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

    case "${_PAGER_PROG}" in
        batcat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | batcat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" . | batcat --style=plain ;;
        bat) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | bat --style=plain || grep -iIHRn ${COLOR_OPT} -- "$1" . | bat --style=plain ;;
        *) command -v rg >/dev/null 2>&1 && rg --hidden -i -n -L ${COLOR_OPT} ${NO_IGNORE_OPT} -- "$1" . | less || grep -iIHRn ${COLOR_OPT} -- "$1" . | less ;;
    esac
}

# Find a filename in the current directory.
ffile() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: ffile [options] <name-pattern>"
        echo "       ffile -h | --help"
        echo ""
        echo "Find a filename in the current directory."
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
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: frfile [options] <name-pattern>"
        echo "       frfile -h | --help"
        echo ""
        echo "Find a filename recursively below the current directory."
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
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: cpp <source> <destination>"
        echo "       cpp -h | --help"
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
        echo "       ld -h | --help"
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
        echo "       lad -h | --help"
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
        echo "       lld -h | --help"
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
        echo "       lltd -h | --help"
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
        echo "       llld -h | --help"
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
        echo "       llltd -h | --help"
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
        echo "       man -h | --help"
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
        echo "       mktext -h | --help"
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
        echo "       t -h | --help"
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
        echo "       taa -h | --help"
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
        echo "       tbg -h | --help"
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
        echo "       tsp -h | --help"
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
        echo "       tlast -h | --help"
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
        echo "       tnl -h | --help"
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
        echo "       _tp_sessions -h | --help"
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
        echo "       tp -h | --help"
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
        echo "       y -h | --help"
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

# Show information about a port and the process using it.
portinfo() {
    # Help flag check
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: portinfo [port]"
        echo "       portinfo -h | --help"
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
            if [[ -n "$podman_cid" ]]; then
                echo "Podman Container Details:"
                podman ps --filter "id=$podman_cid" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
            elif [[ "$cmd" == *"conmon"* ]]; then
                local cid=$(echo "$cmd" | grep -oE '\-c [0-9a-f]{12,64}' | awk '{print $2}')
                if [[ -n "$cid" ]]; then
                    echo "Podman Container Details:"
                    podman ps --filter "id=$cid" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
                fi
            elif [[ "$cmd" == *"rootlessport"* || "$cmd" == *"podman"* ]]; then
                echo "Podman Container Details:"
                podman ps --filter "publish=$port" --format "$fmt_str" 2>/dev/null | sed 's/^/  /'
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
        echo "       processinfo -h | --help"
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
                if [[ -n "$podman_cid" ]]; then
                    echo "${s_indent}Podman Container Details:"
                    podman ps --filter "id=$podman_cid" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                elif [[ "$cmd" == *"conmon"* ]]; then
                    local cid=$(echo "$cmd" | grep -oE '\-c [0-9a-f]{12,64}' | awk '{print $2}')
                    if [[ -n "$cid" ]]; then
                        echo "${s_indent}Podman Container Details:"
                        podman ps --filter "id=$cid" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                    fi
                elif [[ "$cmd" == *"rootlessport"* || "$cmd" == *"podman"* ]]; then
                    local bound_port=$(echo "$sockets" | awk 'NR>1 {print $9}' | grep -oE '[0-9]+$' | head -n 1)
                    if [[ -n "$bound_port" ]]; then
                        echo "${s_indent}Podman Container Details:"
                        podman ps --filter "publish=$bound_port" --format "$fmt_str" 2>/dev/null | sed "s/^/$c_indent/"
                    fi
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
