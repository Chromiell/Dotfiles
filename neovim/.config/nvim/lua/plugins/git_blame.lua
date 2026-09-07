return {
    {
        "FabijanZulj/blame.nvim",
        cmd = "BlameToggle",
        opts = {
            date_format = "%Y-%m-%d",
            -- This creates a clean, GitLens-style sidebar layout
            format_fn = function(line_porcelain, config, idx)
                local hash = string.sub(line_porcelain.hash, 1, 7)
                local date = os.date(config.date_format, line_porcelain.committer_time)
                local author = string.format("%-15s", string.sub(line_porcelain.author, 1, 15))

                return {
                    idx = idx,
                    values = {
                        { textValue = hash, hl = "Comment" },
                        { textValue = " " .. date, hl = "Number" },
                        { textValue = " " .. author, hl = "Statement" },
                    },
                    format = "%s%s%s",
                }
            end,
        },
        -- Map it to `<leader>gm` (Git Blame sidebar)
        keys = {
            { "<leader>gm", "<cmd>BlameToggle<cr>", desc = "Git Blame Sidebar" },
        },
    },
}
