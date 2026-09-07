return {
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "LazyFile",
        enabled = true,
        -- Pass options as a plain table to adjust layout settings safely
        opts = {
            mode = "topline",
            max_lines = 3,
            trim_scope = "inner",
            multiline_threshold = 1,
            min_window_height = 15, -- Stops layout ghosting inside empty windows
            separator = "─",
            zindex = 20,
        },
        -- Explicitly define the keymap so lazy.nvim forces the mapping
        keys = {
            {
                "<leader>ut",
                function()
                    local tsc = require("treesitter-context")
                    if tsc.enabled() then
                        tsc.disable()
                        vim.notify("Disabled Treesitter Context", vim.log.levels.INFO, { title = "Treesitter" })
                    else
                        tsc.enable()
                        vim.notify("Enabled Treesitter Context", vim.log.levels.INFO, { title = "Treesitter" })
                    end
                end,
                desc = "Toggle Treesitter Context",
            },
        },
    },
}
