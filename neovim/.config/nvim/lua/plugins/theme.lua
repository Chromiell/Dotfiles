return {
    {
        "folke/tokyonight.nvim",
        opts = {
            style = "moon", -- Ensures you stay on the Moon variant
            on_highlights = function(hl, c)
                -- Sets the relative line numbers to a lighter, more visible color
                hl.LineNrAbove = { fg = c.fg_dark }
                hl.LineNrBelow = { fg = c.fg_dark }
                hl.TreesitterContextLineNumber = { fg = c.fg_dark }

                -- Optional: If you want them even brighter (matching your main text color):
                -- hl.LineNrAbove = { fg = c.fg }
                -- hl.LineNrBelow = { fg = c.fg }

                -- Optional: Use a specific custom hex code if you want total control:
                -- hl.LineNrAbove = { fg = "#787c99" }
                -- hl.LineNrBelow = { fg = "#787c99" }
            end,
        },
    },
}
