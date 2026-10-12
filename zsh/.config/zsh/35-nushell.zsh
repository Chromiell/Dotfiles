# Nushell-style structured data verbs and producers (jc + jq).

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

# Strip JSONC extras (// and /* */ comments, trailing commas) from stdin so jq
# can read it; plain JSON passes through unchanged. Needs python3 (preinstalled
# on Debian); without it the input goes to jq as is.
typeset -g _NU_JSONC_PY='
import sys
s = sys.stdin.read()
n = len(s)
out = []
i = 0
instr = False
while i < n:
    c = s[i]
    if instr:
        out.append(c)
        if c == "\\" and i + 1 < n:
            out.append(s[i + 1])
            i += 2
            continue
        if c == "\"":
            instr = False
        i += 1
    elif c == "\"":
        instr = True
        out.append(c)
        i += 1
    elif s.startswith("//", i):
        j = s.find("\n", i)
        i = n if j < 0 else j
    elif s.startswith("/*", i):
        j = s.find("*/", i + 2)
        i = n if j < 0 else j + 2
        out.append(" ")
    else:
        out.append(c)
        i += 1
t = "".join(out)
res = []
instr = False
i = 0
n = len(t)
while i < n:
    c = t[i]
    if instr:
        res.append(c)
        if c == "\\" and i + 1 < n:
            res.append(t[i + 1])
            i += 2
            continue
        if c == "\"":
            instr = False
    elif c == "\"":
        instr = True
        res.append(c)
    elif c == ",":
        j = i + 1
        while j < n and t[j].isspace():
            j += 1
        if j >= n or t[j] not in "}]":
            res.append(c)
    else:
        res.append(c)
    i += 1
sys.stdout.write("".join(res))
'

_nu_jsonc() {
    if (( $+commands[python3] )); then python3 -I -c "$_NU_JSONC_PY"; else cat; fi
}

# Load structured data into the verb pipeline, always emitting a JSON array.
# Two modes, so every jc parser and every common config format feeds the verbs:
#   - file/stdin mode: JSON, YAML, TOML or XML from a file or stdin. The format
#     comes from the file extension or -t/--type (required for stdin).
#   - command mode: run a command and parse its output with the matching jc
#     parser. The parser is picked here and the output piped into it instead of
#     using jc "magic" syntax ('jc <command> [args]'): some parsers (find, ...)
#     have no magic support, and magic mode reads the command's own flags as
#     jc flags ('jc find . -iname x' turns -iname into jc's -a and prints jc's
#     info).
# A first argument that is an existing file with a known extension, "-", or
# piped stdin with no arguments selects file mode; anything else is run as a
# command.
fromq() {
    _nu_help "$1" && {
        printf '%s\n' \
        "Usage: fromq [-t json|yaml|toml|xml] [file]" \
        "       <...> | fromq [-t json|yaml|toml|xml]" \
        "       fromq <command> [args...]" \
        "       fromq --help" \
        "" \
        "Load data into the verb pipeline as a JSON array (a single top-level" \
        "object or YAML/TOML/XML document becomes a one-element array)." \
        "" \
        "File mode: parse <file> or stdin as JSON, YAML, TOML or XML. The format" \
        "is taken from -t, else the extension (.json .jsonc .yaml .yml .toml" \
        ".xml), else (stdin) detected from the content. JSON may contain" \
        "JSONC comments and trailing commas (needs python3 to strip them)." \
        "YAML and XML need jc's optional Python" \
        "modules (ruamel.yaml, xmltodict); TOML uses python3's tomllib." \
        "XML follows xmltodict: attributes become '@name' keys, repeated tags" \
        "become arrays." \
        "" \
        "Command mode: run <command> and parse its output with the matching jc" \
        "parser (longest registered match such as 'git log', 'pip list', else" \
        "the parser named after the command, find -> --find). The command runs" \
        "directly, so its flags never reach jc. Some parsers expect specific" \
        "flags (e.g. ls needs -l); 'jc --help' lists all parsers." \
        "" \
        "Example: fromq config.yaml | unnest services | pretty" \
        "         cat opencode.jsonc | fromq | pretty" \
        "         curl -s https://example.com/feed.xml | fromq -t xml | flatten | pretty" \
        "         fromq lsblk | where type eq disk | pretty" \
        "         fromq find . -iname '*readme*' | sel path node | pretty" \
        "         fromq git log -n 20 | sel commit author date message | pretty" \
        "         fromq dig example.com | unnest answer | pretty"
        return 0
    }
    local fmt="" file="" ext data
    while (( $# )); do
        case "$1" in
            -t|--type)
                (( $# >= 2 )) || { echo "fromq: $1 needs a format (json, yaml, toml, xml)" >&2; return 1 }
                fmt="${(L)2}"; shift 2 ;;
            --type=*) fmt="${(L)1#--type=}"; shift ;;
            *) break ;;
        esac
    done
    fmt="${fmt/#yml/yaml}"; fmt="${fmt/#jsonc/json}"
    if [[ -n "$fmt" && "$fmt" != (json|yaml|toml|xml) ]]; then
        echo "fromq: unknown format '$fmt' (use json, yaml, toml or xml)" >&2
        return 1
    fi

    # Decide the mode: a data file argument (or "-"), -t with optional file, or
    # piped stdin with no arguments (format auto-detected). Anything else is a
    # command to run.
    local datamode=0
    if (( $# == 0 )) && [[ ! -t 0 ]]; then
        datamode=1; file=-
    elif [[ -n "$fmt" ]]; then
        (( $# <= 1 )) || { echo "fromq: -t takes at most one file" >&2; return 1 }
        datamode=1; file="${1:--}"
    elif (( $# == 1 )) && [[ "$1" == - ]]; then
        datamode=1; file=-
    elif (( $# == 1 )) && [[ -f "$1" ]]; then
        ext="${(L)1:e}"
        ext="${ext/#yml/yaml}"; ext="${ext/#jsonc/json}"
        if [[ "$ext" == (json|yaml|toml|xml) ]]; then
            fmt="$ext"; datamode=1; file="$1"
        fi
    fi

    if (( datamode )); then
        if [[ "$file" == - ]]; then
            [[ -t 0 ]] && { echo "fromq: nothing on stdin (give a file, or pipe JSON/YAML/TOML/XML in)" >&2; return 1 }
            data="$(cat)"
        elif [[ -r "$file" ]]; then
            data="$(<"$file")"
        else
            echo "fromq: cannot read '$file'" >&2
            return 1
        fi
        # Unknown format: sniff it. JSON/JSONC and XML are recognizable by their
        # first character; TOML is tried before YAML because nearly any text
        # (including TOML's "key = value") is also a valid YAML scalar.
        if [[ -z "$fmt" ]]; then
            local head="${data##[[:space:]]#}"
            if [[ "$head" == ([\{\[]|//|/\*)* ]]; then fmt=json
            elif [[ "$head" == \<* ]]; then fmt=xml
            elif printf '%s\n' "$data" | jc --toml >/dev/null 2>&1; then fmt=toml
            else fmt=yaml; fi
        fi
        setopt localoptions pipefail
        # jc yaml/toml/xml read stdin; JSON goes through jq (after dropping
        # JSONC comments and trailing commas, see _nu_jsonc).
        {
            if [[ "$fmt" == json ]]; then
                printf '%s\n' "$data" | _nu_jsonc | jq '.'
            else
                printf '%s\n' "$data" | jc "--$fmt"
            fi
        } | jq 'if type == "array" then
                    (if length == 1 and (.[0] | type) == "array" then .[0] else . end)
                 else [.] end' || {
            [[ "$fmt" == (yaml|xml) ]] && echo "fromq: $fmt parsing needs jc's optional Python module (pip/apt: ruamel.yaml for yaml, xmltodict for xml)" >&2
            return 1
        }
        return 0
    fi

    (( $# )) || { echo "fromq: need a file, -t <format> with stdin, or a command to run (e.g. fromq lsblk)" >&2; return 1 }
    # jc parser metadata (argument, name, magic commands), cached per session
    if [[ -z "${_NU_JC_PARSERS-}" ]]; then
        typeset -g _NU_JC_PARSERS
        _NU_JC_PARSERS=$(jc -a | jq -c '[.parsers[] | {argument, name, magic: (.magic_commands // [])}]') || return 1
    fi
    local parser
    parser=$(jq -rn --argjson ps "$_NU_JC_PARSERS" --args '
        $ARGS.positional as $a |
        ([$a[0] | split("/")[-1]] + $a[1:]) as $cmd |
        # longest registered magic command matching the start of the line
        (([$ps[] | .argument as $arg | .magic[] | split(" ") as $w
           | select($cmd[0:($w | length)] == $w) | {arg: $arg, n: ($w | length)}]
          | max_by(.n) | .arg)
         // first($ps[] | select(.name == ($cmd[0] | gsub("-"; "_"))) | .argument)
         // "")' -- "$@") || return 1
    [[ -n "$parser" ]] || {
        echo "fromq: jc has no parser for '$1' ('jc --help' lists the supported commands)" >&2
        return 1
    }
    setopt localoptions pipefail
    LC_ALL=C command "$@" | jc "$parser" | jq 'if type == "array" then . else [.] end'
}

# Complete fromq's arguments like a fresh command line (as for nohup/sudo).
compdef _precommand fromq

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
        echo "Example: fromq lsblk | flatten | pretty"
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
        echo "Example: fromq id | unnest groups | pretty"
        echo "         fromq dig example.com | unnest answer | sel name type data | pretty"
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
