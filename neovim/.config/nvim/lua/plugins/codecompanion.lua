return {
    -- 1. Register Which-Key Group
    {
        "folke/which-key.nvim",
        opts = {
            spec = {
                { "<leader>a", group = "AI Assistant", icon = { icon = "", color = "green" }, mode = { "n", "v" } },
            },
        },
    },

    -- 2. Configure CodeCompanion
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("codecompanion").setup({
                adapters = {
                    http = {
                        gemini = function()
                            return require("codecompanion.adapters").extend("gemini", {
                                schema = {
                                    model = {
                                        default = "gemini-3.6-flash",
                                        choices = {
                                            "gemini-3.7-flash",
                                            "gemini-3.6-flash",
                                            "gemini-3.5-flash",
                                            "gemini-3.5-flash-lite",
                                        },
                                    },
                                },
                                env = { api_key = "GEMINI_API_KEY" },
                            })
                        end,
                        codestral = function()
                            return require("codecompanion.adapters").extend("mistral", {
                                name = "codestral",
                                url = "https://codestral.mistral.ai/v1/chat/completions",
                                schema = { model = { default = "codestral-latest" } },
                                env = { api_key = "CODESTRAL_API_KEY" },
                            })
                        end,
                        devstral = function()
                            return require("codecompanion.adapters").extend("mistral", {
                                name = "devstral",
                                schema = {
                                    model = {
                                        default = "devstral-latest",
                                        choices = {
                                            "devstral-latest",
                                            "devstral-small-latest",
                                        },
                                    },
                                },
                                env = { api_key = "CODESTRAL_API_KEY" },
                            })
                        end,
                    },
                },
                strategies = {
                    chat = { adapter = "gemini" },
                    inline = { adapter = "gemini" },
                },
            })
        end,
        keys = {
            { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle AI Chat", mode = { "n", "v" } },
            { "<leader>ai", "<cmd>CodeCompanion<cr>", desc = "AI Inline Instruction", mode = { "n", "v" } },
            { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions Menu", mode = { "n", "v" } },
        },
    },
}
