-- This is a sample configuration for integrating GitHub Copilot into LazyVim.
if true then return {} end

return {
    -- 1. Disable Copilot in the completion menu (to use ghost text instead)
    {
        "LazyVim/LazyVim",
        opts = {
            ai_cmp = false,
        },
    },

    -- 2. Configure copilot.lua
    {
        "zbirenbaum/copilot.lua",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                -- This ensures suggestions appear even when the completion menu is open
                hide_during_completion = false,
                -- Lower debounce means it reacts faster as you type inside a line
                debounce = 75,
                keymap = {
                    -- We handle <Tab> inside the cmp/blink config to prevent conflicts
                    accept = false,
                    next = "<M-]>",
                    prev = "<M-[>",
                },
            },
        },
        config = function(_, opts)
            require("copilot").setup(opts)

            -- BRIGHTEN GHOST TEXT: Override the highlight group
            -- You can change the hex color to match your specific theme's palette
            vim.api.nvim_set_hl(0, "CopilotSuggestion", {
                fg = "#8aa4b7", -- Brighter grayish-blue
                italic = true,
            })

            -- Clear lingering ghost text when exiting insert mode via Ctrl+C
            vim.keymap.set("i", "<C-c>", function()
                local copilot = require("copilot.suggestion")
                if copilot.is_visible() then
                    copilot.dismiss()
                end
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), "n", true)
            end, { desc = "Dismiss Copilot suggestion and exit insert mode" })
        end,
    },

    -- 3. If you are using nvim-cmp: Fix Overlap & Tab Conflict
    {
        "hrsh7th/nvim-cmp",
        optional = true,
        opts = function(_, opts)
            local cmp = require("cmp")

            -- Disable cmp's ghost text to prevent overlapping with Copilot
            opts.experimental = opts.experimental or {}
            opts.experimental.ghost_text = false

            -- Inject Copilot into the <Tab> mapping
            opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
                local copilot = require("copilot.suggestion")

                if copilot.is_visible() then
                    copilot.accept()
                elseif cmp.visible() then
                    cmp.select_next_item()
                elseif vim.snippet.active({ direction = 1 }) then
                    vim.schedule(function()
                        vim.snippet.jump(1)
                    end)
                else
                    fallback()
                end
            end, { "i", "s" })
        end,
    },

    -- 4. If you are using blink.cmp (LazyVim 13.0+ default): Fix Overlap & Tab Conflict
    {
        "saghen/blink.cmp",
        optional = true,
        opts = {
            completion = {
                -- Disable blink's ghost text to prevent overlapping with Copilot
                ghost_text = { enabled = false },
            },
            keymap = {
                -- Inject Copilot into the <Tab> mapping
                ["<Tab>"] = {
                    function()
                        local copilot = require("copilot.suggestion")
                        if copilot.is_visible() then
                            copilot.accept()
                            return true
                        end
                    end,
                    "select_next",
                    "snippet_forward",
                    "fallback",
                },
            },
        },
    },
}
