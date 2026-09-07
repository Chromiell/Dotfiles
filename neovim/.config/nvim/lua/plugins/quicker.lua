return {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    opts = {
        -- This runs automatically every time a quickfix window opens
        on_qf = function(bufnr)
            -- 1. Fix single line deletion (dd)
            vim.keymap.set("n", "dd", function()
                local current_line = vim.fn.line(".")
                local winid = vim.api.nvim_get_current_win()
                local is_loc = vim.fn.getwininfo(winid)[1].loclist == 1
                local qf_list = is_loc and vim.fn.getloclist(0) or vim.fn.getqflist()

                if qf_list[current_line] then
                    -- Remove from the internal data array
                    table.remove(qf_list, current_line)

                    -- Sync changes back to Neovim core
                    if is_loc then
                        vim.fn.setloclist(0, qf_list, "r")
                    else
                        vim.fn.setqflist(qf_list, "r")
                    end

                    -- Force quicker to clear its memory cache and redraw
                    pcall(require("quicker").refresh, winid, { invalidate_cache = true })

                    -- Snap the cursor onto a valid line
                    local new_line = math.min(current_line, #qf_list)
                    if new_line > 0 then
                        vim.fn.cursor(new_line, 1)
                    end
                end
            end, { buffer = bufnr, silent = true, desc = "Delete item from quickfix" })

            -- 2. Fix visual block deletion (d)
            vim.keymap.set("x", "d", function()
                local start_line = vim.fn.line("v")
                local end_line = vim.fn.line(".")
                if start_line > end_line then
                    start_line, end_line = end_line, start_line
                end

                local winid = vim.api.nvim_get_current_win()
                local is_loc = vim.fn.getwininfo(winid)[1].loclist == 1
                local qf_list = is_loc and vim.fn.getloclist(0) or vim.fn.getqflist()

                -- Remove items from back-to-front so list indices don't break during iteration
                for i = end_line, start_line, -1 do
                    if qf_list[i] then
                        table.remove(qf_list, i)
                    end
                end

                if is_loc then
                    vim.fn.setloclist(0, qf_list, "r")
                else
                    vim.fn.setqflist(qf_list, "r")
                end

                pcall(require("quicker").refresh, winid, { invalidate_cache = true })

                local new_line = math.min(start_line, #qf_list)
                if new_line > 0 then
                    vim.fn.cursor(new_line, 1)
                end
            end, { buffer = bufnr, silent = true, desc = "Delete selected items from quickfix" })
        end,
    },
}
