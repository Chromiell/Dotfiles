return {
    "nvim-telescope/telescope.nvim",
    -- Only load the plugin when you actually type :Telescope
    cmd = "Telescope",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-dap.nvim",
    },
    -- We return an empty table for keys to prevent LazyVim
    -- from assigning any default keybindings to this plugin.
    keys = function()
        return {}
    end,
    opts = {
        defaults = {
            -- Optional: Styling it to look distinct from Snacks
            layout_strategy = "horizontal",
            layout_config = { prompt_position = "bottom" },
            sorting_strategy = "descending",
        },
    },
}
