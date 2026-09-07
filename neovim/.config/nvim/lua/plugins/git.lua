return {
    {
        "sindrets/diffview.nvim",
        event = "VeryLazy",
        cmd = { "DiffviewOpen", "DiffviewFileHistory" },
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
            { "<leader>gH", "<cmd>DiffviewFileHistory % --no-merges --follow<cr>", desc = "File History" },
            {
                "<leader>gc",
                function()
                    vim.ui.input({ prompt = "Commit or Range (e.g. hash or commitA..commitB): " }, function(input)
                        if input and input ~= "" then
                            -- If a range (..) is provided, diff directly; otherwise compare single commit to parent (~1)
                            if input:find("%.%.") then
                                vim.cmd("DiffviewOpen " .. input)
                            else
                                vim.cmd("DiffviewOpen " .. input .. "~1.." .. input)
                            end
                        end
                    end)
                end,
                desc = "Diff Commit / Range",
            },
        },
        init = function()
            -- Fine-grained word/character intra-line diffs
            vim.opt.diffopt:append({
                "algorithm:histogram",
                "linematch:60",
            })
        end,
        opts = {
            enhanced_diff_hl = true,
            view = {
                default = {
                    winopts = {
                        wrap = true, -- Enable line wrapping in diff splits
                    },
                },
                merge_tool = {
                    layout = "diff3_mixed",
                },
            },
            hooks = {
                view_opened = function()
                    vim.opt_local.wrap = true
                end,
            },
        },
    },
}
