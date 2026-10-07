-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
-- Enable autoindent for all buffers
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    callback = function()
        vim.opt_local.autoindent = true
    end,
})

-- Detach LSP capabilities from quickfix buffers to prevent interference with quickfix execution
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    desc = "Force detach LSP capabilities from interfering with quickfix execution",
    callback = function(ev)
        local targets = vim.lsp.get_clients({ bufnr = 0 })
        for _, client in ipairs(targets) do
            pcall(vim.lsp.buf_detach_client, ev.buf, client.id)
        end
    end,
})

-- Set commentstring for PHP files to use // instead of /* */
vim.api.nvim_create_autocmd("FileType", {
    pattern = "php",
    callback = function()
        vim.bo.commentstring = "// %s"
    end,
})

-- Set indentation to 4 spaces for SCSS and CSS files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scss", "css" },
    callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
        vim.opt_local.softtabstop = 4
    end,
})

-- MJML is HTML-like: use HTML comments instead of Neovim's default /* */
vim.api.nvim_create_autocmd("FileType", {
    pattern = "mjml",
    callback = function()
        vim.bo.commentstring = "<!-- %s -->"
    end,
})

-- Center screen after half-page scrolling down and up
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Keep the shared `MiniIcons*` highlight groups coloured across colourscheme changes.
--
-- real-icons.nvim's lualine integration emits the icon's highlight group name
-- verbatim (e.g. `%#MiniIconsPurple#󰌟%*`), so lualine registers that *foreign*
-- group as one of its own and its `clear_highlights()` runs
-- `highlight clear MiniIconsPurple` on every `ColorScheme` / `:set background`.
-- Those groups are GLOBAL and shared by the snacks explorer, pickers and
-- bufferline, so the wipe greys out file icons everywhere - not just the
-- statusline. mini.icons' own `ColorScheme` handler only re-links them
-- (`default = true, link = "Constant"`), which never restores the real colours
-- once the group has been cleared, which is what leaves the icons grey.
--
-- Theme independence: rather than re-deriving the colours from one specific
-- theme, this remembers whatever colours the *active* colourscheme painted and
-- re-asserts them after lualine's synchronous handler has finished clearing the
-- groups. It therefore works with any colourscheme that defines `MiniIcons*`.
-- See README section 8 ("Why icons turned grey").
local MINI_ICON_GROUPS = {
    "MiniIconsAzure",
    "MiniIconsBlue",
    "MiniIconsCyan",
    "MiniIconsGreen",
    "MiniIconsGrey",
    "MiniIconsOrange",
    "MiniIconsPurple",
    "MiniIconsRed",
    "MiniIconsYellow",
}

local mini_icons_hl_cache = {}

-- Only remember genuine colours, so a group lualine already wiped (empty) or
-- that mini.icons re-linked (`default = true, link = ...`) never overwrites a
-- good cached value.
local function remember_mini_icons_highlights()
    for _, name in ipairs(MINI_ICON_GROUPS) do
        local hl = vim.api.nvim_get_hl(0, { name = name })
        if hl and hl.fg and not hl.link then
            mini_icons_hl_cache[name] = hl
        end
    end
end

local function restore_mini_icons_highlights()
    remember_mini_icons_highlights()
    -- Defer so we run on the next event-loop tick, i.e. after lualine's
    -- synchronous ColorScheme handler has run `highlight clear MiniIcons*`.
    vim.schedule(function()
        for name, hl in pairs(mini_icons_hl_cache) do
            vim.api.nvim_set_hl(0, name, hl)
        end
    end)
end

local mini_icons_augroup = vim.api.nvim_create_augroup("UserMiniIconsHighlights", { clear = true })

-- Seed the cache as soon as the colourscheme is up, before any icon has been
-- drawn in the statusline (drawing is what makes lualine start clearing them).
vim.api.nvim_create_autocmd({ "UIEnter", "VimEnter" }, {
    group = mini_icons_augroup,
    callback = remember_mini_icons_highlights,
})

vim.api.nvim_create_autocmd("User", {
    group = mini_icons_augroup,
    pattern = "VeryLazy",
    callback = remember_mini_icons_highlights,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    group = mini_icons_augroup,
    callback = restore_mini_icons_highlights,
})

vim.api.nvim_create_autocmd("OptionSet", {
    group = mini_icons_augroup,
    pattern = "background",
    callback = restore_mini_icons_highlights,
})
