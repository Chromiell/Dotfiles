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

# OpenCode / oh-my-opencode-slim
# Enable native V2 background (async) subagent sessions, which the
# oh-my-opencode-slim orchestrator uses to plan, dispatch, and reconcile
# parallel specialist agents.
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
# Enable OpenCode's built-in Exa-backed web search without a separate API key.
export OPENCODE_ENABLE_EXA=1
