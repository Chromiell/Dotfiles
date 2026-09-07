return {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    keys = {
        {
            "<leader>y",
            "<cmd>Yazi<cr>",
            desc = "Open Yazi at current file",
        },
        {
            "<leader>Y",
            "<cmd>Yazi cwd<cr>",
            desc = "Open Yazi in working directory",
        },
    },

    opts = {
        open_for_directories = false,
        keymaps = {
            show_help = "<f1>",
        },

        -- we keep opts clean; no unreliable env injection here
    },

    config = function(_, opts)
        require("yazi").setup(opts)

        -- 🔧 patch environment for all Yazi launches
        local original_cmd = vim.fn.executable

        vim.fn.executable = function(cmd)
            if cmd == "yazi" then
                vim.env.YAZI_CONFIG_HOME = vim.fn.expand("~/.config/nvim_yazi")
            end
            return original_cmd(cmd)
        end
    end,
}
