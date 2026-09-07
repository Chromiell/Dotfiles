-- Uses treesitter to provide % matching for html tags, etc.
return {
    {
        "andymass/vim-matchup",
        event = "BufReadPost",
        init = function()
            -- Defers highlighting updates until cursor stops, preventing insert-mode event collisions
            vim.g.matchup_matchparen_deferred = 1
            vim.g.matchup_matchparen_deferred_show_delay = 50
            -- Prevents synchronous match updates from blocking typed characters in insert mode
            vim.g.matchup_matchparen_insert_timeout = 60
        end,
        keys = {
            {
                "<leader>cM",
                function()
                    local is_enabled = (vim.g.matchup_enabled == nil or vim.g.matchup_enabled == 1)

                    if is_enabled then
                        -- 1. Disable flags globally and for buffer
                        vim.g.matchup_enabled = 0
                        vim.g.matchup_matchparen_enabled = 0
                        vim.b.matchup_enabled = 0
                        vim.b.matchup_matchparen_enabled = 0

                        -- 2. Stop highlighting engine
                        vim.fn["matchup#matchparen#disable"]()

                        -- 3. Restore LazyVim's default matchit behavior
                        vim.keymap.set("n", "%", "<Plug>(MatchitNormalForward)", { remap = true, silent = true })
                        vim.keymap.set("x", "%", "<Plug>(MatchitVisualForward)", { remap = true, silent = true })
                        vim.keymap.set("o", "%", "<Plug>(MatchitOperationForward)", { remap = true, silent = true })

                        vim.notify("vim-matchup disabled", vim.log.levels.INFO)
                    else
                        -- 1. Re-enable flags
                        vim.g.matchup_enabled = 1
                        vim.g.matchup_matchparen_enabled = 1
                        vim.b.matchup_enabled = 1
                        vim.b.matchup_matchparen_enabled = 1

                        -- 2. Start highlighting engine
                        vim.fn["matchup#matchparen#enable"]()

                        -- 3. Rebind % back to vim-matchup
                        vim.keymap.set("n", "%", "<Plug>(matchup-%)", { remap = true, silent = true })
                        vim.keymap.set("x", "%", "<Plug>(matchup-%)", { remap = true, silent = true })
                        vim.keymap.set("o", "%", "<Plug>(matchup-%)", { remap = true, silent = true })

                        vim.notify("vim-matchup enabled", vim.log.levels.INFO)
                    end
                end,
                desc = "Toggle vim-matchup",
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            matchup = {
                enable = true, -- Enables Treesitter integration for vim-matchup
            },
        },
    },
}
