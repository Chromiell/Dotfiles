-- This file is for configuring the Copilot Chat plugin for Neovim.
if true then return {} end

return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        opts = {
            -- Change this to "gpt-4o-mini" or your desired model ID
            model = "gpt-5-mini",
        },
    },
}
