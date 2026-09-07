# XDG Base Directory Specification (extended)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:=${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:=${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:=${HOME}/.local/state}"

# Optional but widely adopted
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_BIN_HOME="${XDG_BIN_HOME:=${HOME}/.local/bin}"

# Default editor programs
export EDITOR="micro"
export VISUAL="micro"

# Required by zsh-autocomplete
skip_global_compinit=1
