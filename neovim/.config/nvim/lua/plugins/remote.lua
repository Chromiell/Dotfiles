return {
    -- 1. Safely extend the Which-Key spec without overwriting defaults
    {
        "folke/which-key.nvim",
        opts = function(_, opts)
            opts.spec = opts.spec or {}
            table.insert(opts.spec, {
                "<leader>r",
                group = "remote",
                icon = { icon = "󰖟", color = "azure" },
                mode = { "n", "v" },
            })
        end,
    },
    -- 2. Configure the remote-nvim plugin
    {
        "amitds1997/remote-nvim.nvim",
        version = "*",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-telescope/telescope.nvim",
        },
        keys = {
            { "<leader>rs", "<cmd>RemoteStart<cr>", desc = "Remote SSH Start" },

            -- Interactive UI Selection for Deleting local records
            {
                "<leader>rd",
                function()
                    -- Safely capture plugin's registered hosts via its tab-completion list
                    local connections = vim.fn.getcompletion("RemoteConfigDel ", "cmdline")

                    if vim.tbl_isempty(connections) then
                        vim.notify("No saved connections found.", vim.log.levels.WARN, { title = "Remote Nvim" })
                        return
                    end

                    vim.ui.select(connections, {
                        prompt = "Select a saved connection profile to DELETE:",
                    }, function(choice)
                        if choice then
                            vim.cmd("RemoteConfigDel " .. choice)
                            vim.notify(
                                "Successfully removed profile: " .. choice,
                                vim.log.levels.INFO,
                                { title = "Remote Nvim" }
                            )
                        end
                    end)
                end,
                desc = "Delete Saved Connection Record",
            },

            -- Interactive UI Selection for Remote server cleanup
            {
                "<leader>rc",
                function()
                    -- Capture active profiles eligible for complete environment wipes
                    local connections = vim.fn.getcompletion("RemoteCleanup ", "cmdline")

                    if vim.tbl_isempty(connections) then
                        vim.notify(
                            "No remote workspaces available to clean up.",
                            vim.log.levels.WARN,
                            { title = "Remote Nvim" }
                        )
                        return
                    end

                    vim.ui.select(connections, {
                        prompt = "Select a remote host to WIPE & CLEAN UP:",
                    }, function(choice)
                        if choice then
                            vim.cmd("RemoteCleanup " .. choice)
                        end
                    end)
                end,
                desc = "Cleanup Remote Workspace & Config",
            },
        },
        opts = {},
    },
}
