-- Laravel support: Blade treesitter/filetype, blade-formatter, and laravel.nvim.
--
-- laravel.nvim (https://github.com/adalessa/laravel.nvim) adds a first-class
-- Laravel editing layer on top of LazyVim: pickers (artisan / routes / make /
-- resources / custom commands), virtual model & route info, Blade-aware `gf`,
-- tinker, an Artisan Hub, code actions and completion. It is gated on a Laravel
-- project, so it is a no-op in non-Laravel buffers, and it generates small
-- server-side helpers into the project's `vendor/` directory (which must be
-- writable).
--
-- Notes for this config:
--   * Pickers are backed by snacks.picker (the primary picker here); completion
--     plugs into blink.cmp automatically.
--   * Keymaps live under `<leader>v` (a dedicated which-key group) because
--     LazyVim reserves `<leader>l` for `:Lazy` and `<leader>L` for its changelog.
--   * `gf` is extended (lua/config/laravel_middleware.lua) to also jump to the
--     class behind a middleware alias string, which laravel.nvim does not do.
local middleware = require("config.laravel_middleware")

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
        "mason-org/mason.nvim",
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

    -- 4. Register the Which-Key group for the laravel.nvim keymaps below
    {
        "folke/which-key.nvim",
        opts = function(_, opts)
            opts.spec = opts.spec or {}
            table.insert(opts.spec, {
                "<leader>v",
                group = "Laravel",
                -- U+E73F = Nerd Font "laravel" devicon
                icon = { icon = "", color = "red" },
                mode = { "n" },
            })
        end,
    },

    -- 5. laravel.nvim
    {
        "adalessa/laravel.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-neotest/nvim-nio",
        },
        ft = { "php", "blade" },
        event = { "BufEnter composer.json" },
        keys = {
            {
                "<leader>vl",
                function()
                    Laravel.pickers.laravel()
                end,
                desc = "Laravel: Master Picker",
            },
            {
                "<leader>va",
                function()
                    Laravel.pickers.artisan()
                end,
                desc = "Laravel: Artisan Picker",
            },
            {
                "<leader>vr",
                function()
                    Laravel.pickers.routes()
                end,
                desc = "Laravel: Routes Picker",
            },
            {
                "<leader>vm",
                function()
                    Laravel.pickers.make()
                end,
                desc = "Laravel: Make Picker",
            },
            {
                "<leader>vc",
                function()
                    Laravel.pickers.commands()
                end,
                desc = "Laravel: Custom Commands",
            },
            {
                "<leader>vo",
                function()
                    Laravel.pickers.resources()
                end,
                desc = "Laravel: Resources Picker",
            },
            {
                "<leader>vh",
                function()
                    Laravel.run("artisan docs")
                end,
                desc = "Laravel: Documentation",
            },
            {
                "<leader>vt",
                function()
                    Laravel.commands.run("actions")
                end,
                desc = "Laravel: Code Actions",
            },
            {
                "<leader>vu",
                function()
                    Laravel.commands.run("hub")
                end,
                desc = "Laravel: Artisan Hub",
            },
            {
                "<leader>vp",
                function()
                    Laravel.commands.run("command_center")
                end,
                desc = "Laravel: Command Center",
            },
            {
                "<C-g>",
                function()
                    Laravel.commands.run("view:finder")
                end,
                desc = "Laravel: View Finder",
            },
            {
                "gf",
                function()
                    local alias = middleware.alias_under_cursor()
                    if alias then
                        -- Return a <cmd> (instead of "" + a side effect) so the
                        -- async jump is entered from the main loop, exactly like
                        -- laravel.nvim's own gf; otherwise the buffer switch can
                        -- stay unflushed until the next keypress.
                        return ("<cmd>lua require('config.laravel_middleware').goto_alias(%q)<cr>"):format(alias)
                    end
                    if Laravel.app("gf").cursorOnResource() then
                        return "<cmd>lua Laravel.commands.run('gf')<cr>"
                    end
                    return "gf"
                end,
                expr = true,
                remap = false,
                desc = "Laravel: Go to resource",
            },
        },
        opts = {
            features = {
                pickers = {
                    provider = "snacks",
                },
            },
        },
    },
}
