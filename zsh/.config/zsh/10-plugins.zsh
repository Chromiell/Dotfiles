# Install and initialize Znap, then load the configured Zsh plugins.

# Locate or install the Znap plugin manager.
typeset znap_dir="$HOME/.config/zsh/znap"

if [[ ! -r "$znap_dir/znap.zsh" ]]; then
    print "" # Separate the installation message from the shell prompt.
    print -n "Cloning Znap plugin manager... "
    git clone --depth 1 --quiet -- https://github.com/marlonrichert/zsh-snap.git "$znap_dir" >/dev/null 2>&1
    print "Done!"
fi

source "$znap_dir/znap.zsh"

typeset -a plugins=(
    marlonrichert/zsh-autocomplete
    zsh-users/zsh-history-substring-search
    zdharma-continuum/fast-syntax-highlighting
    romkatv/powerlevel10k
)

# Load each plugin once. Znap fetches plugins that are not installed yet.
for plugin in "${plugins[@]}"; do
    znap source "$plugin"
done
# Znap and all configured plugins are now available.

# Load Deja, the predictive autosuggestion engine (drop-in replacement for
# zsh-autosuggestions). The Go binary is downloaded automatically on first
# run; the zsh integration lives in ~/.local/share/deja/init.zsh.
typeset deja_bin="$HOME/.local/bin/deja"
typeset deja_init="$HOME/.local/share/deja/init.zsh"

if [[ ! -x "$deja_bin" ]]; then
    print "" # Separate the installation message from the shell prompt.
    print -n "Installing Deja autosuggestions... "
    # Minimal Debian installs ship wget but not curl, so accept either.
    # _deja_fetch <url> [<file>]: download to <file>, or to stdout if omitted.
    if command -v curl >/dev/null 2>&1; then
        _deja_fetch() { curl -fsSL -o "${2:--}" -- "$1"; }
    elif command -v wget >/dev/null 2>&1; then
        _deja_fetch() { wget -q -O "${2:--}" -- "$1"; }
    fi
    case "$(uname -m)" in
        x86_64|amd64)  typeset deja_arch="amd64" ;;
        arm64|aarch64) typeset deja_arch="arm64" ;;
    esac
    typeset deja_tmp="$(mktemp -d 2>/dev/null || mktemp -d -t deja)"
    typeset deja_base="https://github.com/Giammarco-Ferranti/deja/releases"
    typeset deja_err=""
    if (( ! $+functions[_deja_fetch] )); then
        deja_err="curl or wget is required"
    elif [[ -z "$deja_arch" ]]; then
        deja_err="unsupported architecture $(uname -m)"
    else
        typeset deja_tag="$(_deja_fetch https://api.github.com/repos/Giammarco-Ferranti/deja/releases/latest \
            | command grep '"tag_name":' | command sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
        typeset deja_asset="deja_${deja_tag#v}_linux_${deja_arch}.tar.gz"
        if [[ -z "$deja_tag" ]]; then
            deja_err="could not query the latest release"
        elif ! _deja_fetch "$deja_base/download/$deja_tag/$deja_asset" "$deja_tmp/$deja_asset" \
            || ! _deja_fetch "$deja_base/download/$deja_tag/checksums.txt" "$deja_tmp/checksums.txt"; then
            deja_err="download failed"
        elif ! (cd "$deja_tmp" && command grep -F "$deja_asset" checksums.txt | sha256sum -c - >/dev/null 2>&1); then
            deja_err="checksum mismatch"
        elif ! command tar -xzf "$deja_tmp/$deja_asset" -C "$deja_tmp"; then
            deja_err="could not extract $deja_asset"
        else
            typeset deja_file="$(command find "$deja_tmp" -type f -name deja -print -quit)"
            if ! { mkdir -p "$HOME/.local/bin" && mv "$deja_file" "$deja_bin" && chmod +x "$deja_bin"; }; then
                deja_err="could not install to $deja_bin"
            fi
        fi
    fi
    if [[ -z "$deja_err" ]]; then
        print "Done!"
    else
        print "Failed! ($deja_err; see https://github.com/Giammarco-Ferranti/deja)"
    fi
    command rm -rf "$deja_tmp"
    unfunction _deja_fetch 2>/dev/null
    unset deja_arch deja_tmp deja_tag deja_asset deja_base deja_file deja_err
fi

if [[ -x "$deja_bin" ]]; then
    # Deja re-asserts its keybindings on every prompt, which would steal Tab
    # ('^I') from the menu-select completion binding further down. Leave Tab
    # alone (empty key) and put suggestion cycling on Ctrl+N instead (see
    # DEJA_CYCLE_KEY docs in ~/.local/share/deja/init.zsh).
    DEJA_CYCLE_KEY='^N'
    # On first run, import the zsh history and generate the integration script
    # ("deja init zsh" writes it to disk and only prints a source line for it).
    if [[ ! -r "$deja_init" ]]; then
        "$deja_bin" import >/dev/null 2>&1
        "$deja_bin" init zsh >/dev/null 2>&1
    fi
    [[ -r "$deja_init" ]] && source "$deja_init"
fi

# Load terminal capability names before using the $terminfo parameter.
zmodload zsh/terminfo

# Make the completion menu available on Tab and Shift-Tab.
bindkey '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

