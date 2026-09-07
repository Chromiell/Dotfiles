return {
    -- 1. Setup Treesitter and Filetype Association
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "blade", "php", "html", "css" })
            end

            vim.filetype.add({
                pattern = {
                    [".*%.blade%.php"] = "blade",
                },
            })
        end,
    },

    -- 2. Automatically install blade-formatter via Mason
    {
        "mason.org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "blade-formatter" })
        end,
    },

    -- 3. Configure formatting using blade-formatter via conform.nvim
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                blade = { "blade-formatter" },
            },
        },
    },
}
