local fn = require("config.functions")

-- Register Commands
vim.api.nvim_create_user_command("ToggleHexHsl", fn.toggle_hex_hsl, {})

-- ============================================================================
-- 1. GENERAL & EDITING
-- ============================================================================

vim.keymap.set("n", " ", "", { desc = "Ignore space", silent = true })
vim.keymap.set("n", "<leader>fP", fn.copy_project_path, { desc = "Copy File Path" })

-- Trailing Whitespace
vim.keymap.set("n", "<leader>ct", fn.trim_whitespace_file, { desc = "Trim Trailing Whitespace (Whole File)" })
vim.keymap.set("v", "<leader>ct", fn.trim_whitespace_selection, { desc = "Trim Trailing Whitespace (Selection)" })

-- Indentation (stays in visual mode after indenting)
vim.keymap.set("n", "<Tab>", ">>", { desc = "Indent line" })
vim.keymap.set("n", "<S-Tab>", "<<", { desc = "Dedent line" })
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent line" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Dedent line" })

-- Marks
vim.keymap.set("n", "<leader>mD", fn.delete_all_marks, { desc = "Delete all marks (all buffers)" })
vim.keymap.set("n", "<leader>md", fn.delete_line_marks, { desc = "Delete all marks on current line" })

-- Buffer Navigation
vim.keymap.set("n", "<leader>b[", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer left" })
vim.keymap.set("n", "<leader>b]", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer right" })

-- ============================================================================
-- 2. SEARCH & NAVIGATION
-- ============================================================================

vim.keymap.set("n", "<leader>\\", fn.grep_latin1, { desc = "Grep (Latin-1 Encoding) in Root" })

local ok, wk = pcall(require, "which-key")
if ok then
    wk.add({
        {
            "<leader>\\",
            icon = { icon = "󱥰", color = "purple", hl = "SnacksIconCandy" },
        },
    })
end

-- Laravel jump to accessor
vim.api.nvim_create_autocmd("FileType", {
    pattern = "php",
    callback = function(event)
        vim.keymap.set("n", "<leader>cj", fn.jump_to_laravel_accessor, {
            buffer = event.buf,
            desc = "Jump to Laravel Accessor",
        })
    end,
})

-- ============================================================================
-- 3. LSP, DIAGNOSTICS & SPELLCHECK
-- ============================================================================

vim.keymap.set("n", "<leader>ck", vim.lsp.buf.signature_help, { desc = "Signature Help" })

-- LSP Hints
vim.keymap.set("n", "]n", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.HINT })
end, { desc = "Next Hint" })

vim.keymap.set("n", "[n", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.HINT })
end, { desc = "Previous Hint" })

-- CSpell
vim.keymap.set("n", "]s", fn.jump_to_typo("next"), { desc = "Next spelling typo" })
vim.keymap.set("n", "[s", fn.jump_to_typo("prev"), { desc = "Previous spelling typo" })
vim.keymap.set("n", "<leader>uo", fn.toggle_cspell, { desc = "Toggle CSpell checker" })

-- ============================================================================
-- 4. GIT & DIFFING
-- ============================================================================

vim.keymap.set("n", "<leader>gC", fn.diffview_compare_branches, { desc = "Diffview: Compare 2 Branches" })
vim.keymap.set("n", "<leader>bc", fn.diff_two_buffers, { desc = "Diff 2 buffers (Select with <Tab>)" })
vim.keymap.set("n", "<leader>gb", "<cmd>.DiffviewFileHistory<cr>", { desc = "Diffview Line History" })
vim.keymap.set("v", "<leader>gb", "<cmd>'<,'>DiffviewFileHistory<cr>", { desc = "Diffview Range History" })

-- ============================================================================
-- 5. DEBUGGING (DAP)
-- ============================================================================

vim.keymap.set("n", "<leader>dL", "<cmd>Telescope dap list_breakpoints<cr>", { desc = "Debug: List Breakpoints" })
vim.keymap.set("n", "<leader>dG", function()
    require("dap").focus_frame()
end, { desc = "Debug: Focus current line" })
vim.keymap.set("n", "<leader>dx", function()
    require("dap").clear_breakpoints()
    print("Breakpoints cleared")
end, { desc = "Debug: Clear All Breakpoints" })

-- ============================================================================
-- 6. CONVERTERS & FORMATTING
-- ============================================================================

vim.keymap.set("v", "<leader>cx", fn.toggle_date_timestamp, { desc = "Toggle Date/Timestamp" })
vim.keymap.set("n", "<leader>co", fn.toggle_hex_hsl, { desc = "Toggle Hex <-> HSL Color" })
