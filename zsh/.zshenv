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

# -----------------------------------------------------------------------------------------------
# Change the default directory for many applications that follow XDG Base Directory Specification
# -----------------------------------------------------------------------------------------------
# GnuPG
export GNUPGHOME="$XDG_DATA_HOME"/gnupg

# Node.js
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME"/npm/config/npm-init.js
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME"/npm

# npmrc
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc

# Bash History file
export HISTFILE="${XDG_STATE_HOME}"/bash/history

# .NET Core
export DOTNET_CLI_HOME="$XDG_DATA_HOME"/dotnet

# Rust
export CARGO_HOME="$XDG_DATA_HOME"/cargo

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# Codex
export CODEX_HOME="$XDG_CONFIG_HOME"/codex

# Claude
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME"/claude

# Less History file
export LESSHISTFILE="${XDG_STATE_HOME}"/lesshst

# zsh History file
export HISTFILE="$XDG_STATE_HOME"/.zhistory
# -----------------------------------------------------------------------------------------------

# OpenCode / oh-my-opencode-slim
# Enable native V2 background (async) subagent sessions, which the
# oh-my-opencode-slim orchestrator uses to plan, dispatch, and reconcile
# parallel specialist agents.
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
# Enable OpenCode's built-in Exa-backed web search without a separate API key.
export OPENCODE_ENABLE_EXA=1
