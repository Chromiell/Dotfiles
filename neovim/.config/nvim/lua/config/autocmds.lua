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

-- Center screen after half-page scrolling down and up
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

