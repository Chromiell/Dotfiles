-- Highlight trailing whitespace
return {
    {
        "nvim-mini/mini.trailspace",
        event = "BufReadPost",
        opts = {},
        keys = {
            {
                "<leader>cT",
                function()
                    vim.g.minitrailspace_disable = not vim.g.minitrailspace_disable
                    if vim.g.minitrailspace_disable then
                        require("mini.trailspace").unhighlight()
                        vim.notify("Trailspace highlight disabled", vim.log.levels.INFO)
                    else
                        require("mini.trailspace").highlight()
                        vim.notify("Trailspace highlight enabled", vim.log.levels.INFO)
                    end
                end,
                desc = "Toggle Trailspace Highlighting",
            },
        },
        config = function(_, opts)
            require("mini.trailspace").setup(opts)

            -- Custom red background highlight
            vim.api.nvim_set_hl(0, "MiniTrailspace", { bg = "#681d23", fg = "#686868" })
        end,
    },
}
