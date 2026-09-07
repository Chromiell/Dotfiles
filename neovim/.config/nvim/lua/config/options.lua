-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable word wrap by default
vim.opt.wrap = true
-- Ensure lines wrap at a word boundary instead of mid-word
vim.opt.linebreak = true
-- (Optional) If you want the wrapped line to visually match the indentation
vim.opt.breakindent = true
-- Show invisible characters (tabs and spaces)
vim.opt.list = true
-- Disable autoformat on save
vim.g.autoformat = false

-- Define what characters to use for each whitespace type
vim.opt.listchars = {
    tab = "» ", -- Shows '»' at the start of a tab
    trail = "·", -- Shows '·' for trailing spaces
    nbsp = "␣", -- Shows '␣' for non-breaking spaces
    space = "·", -- Shows '·' for every single space (optional)
    lead = "·", -- Shows '·' for leading spaces (indentation)
}

-- Make whitespace characters very subtle (adjust color as needed)
vim.api.nvim_set_hl(0, "Whitespace", { fg = "#444444" })

-- Change indentation settings to use spaces instead of tabs, and set the width to 4 spaces
vim.opt.shiftwidth = 4 -- Size of an indent
vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.expandtab = true -- Use spaces instead of tabs

vim.opt.autoindent = true -- Copy indent from current line when starting a new one
vim.opt.smartindent = true -- Insert indents automatically in C-like languages
vim.opt.breakindent = true -- Aligns wrapped lines with the indentation of the first line

-- Only show error and hint diagnostics
local function filter_diagnostics()
    local ns = vim.api.nvim_get_namespaces()
    for _, id in pairs(ns) do
        local config = vim.diagnostic.config()
        config.severity = {
            -- Only allow these two
            allow = {
                vim.diagnostic.severity.ERROR,
                vim.diagnostic.severity.HINT,
            },
        }
        vim.diagnostic.config(config, id)
    end
end

-- Run it
filter_diagnostics()

-- This targets the internal Snacks toggle used by <leader>ua
vim.g.snacks_animate = false

-- Disable default key mappings for omni_sql plugin to avoid conflicts with custom mappings
vim.g.omni_sql_no_default_maps = 1
