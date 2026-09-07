return {
    -- 1. Configure minuet-ai.nvim with multiple providers & toggle keymap
    {
        "milanglacier/minuet-ai.nvim",
        config = function()
            local minuet = require("minuet")
            minuet.setup({
                provider = "codestral",
                provider_options = {
                    gemini = {
                        model = "gemini-3.5-flash-lite",
                        api_key = "GEMINI_API_KEY",
                        optional = {
                            generationConfig = {
                                temperature = 0.1,
                                topP = 0.95,
                            },
                        },
                    },
                    codestral = {
                        model = "codestral-latest",
                        api_key = "CODESTRAL_API_KEY",
                    },
                },
                -- Turn off automatic completion triggers from minuet's side
                blink = {
                    enable_auto_complete = false,
                },
                -- SAFETY BUFFER: Keeps your typing experience buttery smooth
                debounce = 300, -- Wait for 300ms of typing silence before making an API call
                throttle = 1000, -- Restrict network requests to a maximum of 1 per second
                virtualtext = {
                    enable = false,
                },
            })

            -- Toggle between Gemini and Codestral providers
            local function toggle_minuet_provider()
                if minuet.config.provider == "gemini" then
                    minuet.config.provider = "codestral"
                    vim.notify("Minuet AI provider: Codestral", vim.log.levels.INFO, { title = "Minuet AI" })
                else
                    minuet.config.provider = "gemini"
                    vim.notify(
                        "Minuet AI provider: Gemini (3.5 Flash Lite)",
                        vim.log.levels.INFO,
                        { title = "Minuet AI" }
                    )
                end
            end

            -- Keymap to toggle provider (<leader>at in Normal mode)
            vim.keymap.set("n", "<leader>at", toggle_minuet_provider, { desc = "Toggle Minuet AI Provider" })
        end,
    },

    -- 2. Instruct blink.cmp to handle manual trigger and render ghost text
    {
        "saghen/blink.cmp",
        opts = function(_, opts)
            -- Ensure native ghost text preview is turned on globally
            opts.completion = opts.completion or {}
            opts.completion.ghost_text = opts.completion.ghost_text or {}
            opts.completion.ghost_text.enabled = true

            -- Dynamic Custom Menu Rendering Interception
            opts.completion.menu = opts.completion.menu or {}
            opts.completion.menu.draw = opts.completion.menu.draw or {}
            opts.completion.menu.draw.components = opts.completion.menu.draw.components or {}
            opts.completion.menu.draw.components.kind_icon = {
                text = function(ctx)
                    -- Check if the item originated from our Minuet source
                    if ctx.source_name == "minuet" or (ctx.item and ctx.item.source_name == "minuet") then
                        return "" .. (ctx.icon_gap or " ")
                    end
                    -- Fallback to the default LSP icons for other providers
                    return ctx.kind_icon .. (ctx.icon_gap or " ")
                end,
                highlight = function(ctx)
                    -- Give the custom robot icon a distinct color
                    if ctx.source_name == "minuet" or (ctx.item and ctx.item.source_name == "minuet") then
                        return "BlinkCmpKindEvent"
                    end
                    return ctx.kind_hl
                end,
            }

            -- Configure the minuet provider parameters
            opts.sources = opts.sources or {}
            opts.sources.providers = opts.sources.providers or {}
            opts.sources.providers.minuet = {
                name = "minuet",
                module = "minuet.blink",
                score_offset = 100, -- Forces tokens directly to the top item slot
                async = true,
                timeout_ms = 3000, -- Gives the cloud stream ample time to resolve tokens
            }

            -- Explicitly strip 'minuet' out of the default auto-trigger listing
            opts.sources.default = vim.tbl_filter(function(source)
                return source ~= "minuet"
            end, opts.sources.default or { "lsp", "path", "snippets", "buffer" })

            -- Bind Alt+A (or Option+A) to manually invoke the active suggestion engine
            vim.keymap.set("i", "<M-a>", function()
                require("blink.cmp").show({ providers = { "minuet" } })
            end, { desc = "Trigger Minuet AI Completion" })

            -- Orchestrate keymaps so Tab accepts whichever ghost text preview is active
            opts.keymap = opts.keymap or {}
            opts.keymap["<Tab>"] = {
                "accept",
                "select_next",
                "snippet_forward",
                "fallback",
            }
        end,
    },
}
