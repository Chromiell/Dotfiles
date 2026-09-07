return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        dependencies = "nvim-treesitter/nvim-treesitter",
        event = "BufReadPost",
        config = function()
            local rb = require("rainbow-delimiters")
            vim.g.rainbow_delimiters = {
                strategy = {
                    [""] = rb.strategy["global"],
                    vim = rb.strategy["local"],
                },
                query = {
                    [""] = "rainbow-delimiters",
                    lua = "rainbow-blocks",
                    -- 1. Silence HTML and XML tags specifically (even inside other files)
                    xml = "",
                    html = "",
                    -- 2. Use 'rainbow-blocks' for JSX/TSX/Vue
                    -- This colors your JS logic ( {} and () ) but ignores the HTML tags (< >)
                    javascriptreact = "rainbow-blocks",
                    typescriptreact = "rainbow-blocks",
                    vue = "rainbow-blocks",
                },
                highlight = {
                    "RainbowDelimiterRed",
                    "RainbowDelimiterYellow",
                    "RainbowDelimiterBlue",
                    "RainbowDelimiterViolet",
                    "RainbowDelimiterCyan",
                },
            }
        end,
    },
}
