return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            -- 1. Define the Git project-wide status function scoped to the current buffer
            local function git_project_status()
                -- Get the full path of the current buffer
                local buf_name = vim.api.nvim_buf_get_name(0)
                if buf_name == "" then
                    return ""
                end

                -- Extract the directory path of the current file
                local buf_dir = vim.fs.dirname(buf_name)
                if not buf_dir then
                    return ""
                end

                -- Check if the buffer's directory is inside a git repo using git -C
                local is_git = os.execute(
                    string.format(
                        "git -C %s rev-parse --is-inside-work-tree >/dev/null 2>&1",
                        vim.fn.shellescape(buf_dir)
                    )
                )
                if is_git ~= 0 then
                    return ""
                end

                -- Run git status from the buffer's directory and count lines
                local cmd =
                    string.format("git -C %s status --porcelain 2>/dev/null | wc -l", vim.fn.shellescape(buf_dir))
                local handle = io.popen(cmd)
                if not handle then
                    return ""
                end

                local result = handle:read("*a")
                handle:close()

                local count = tonumber(result:match("%d+"))
                if count and count > 0 then
                    -- This icon 󰊢 represents a Git branch/repo
                    return "󰊢 " .. count
                end
                return ""
            end

            -- 2. Add the Git counter to the left side (next to branch name)
            table.insert(opts.sections.lualine_b, {
                git_project_status,
                color = { fg = "#ff9e64", gui = "bold" }, -- Orange color similar to VSCode
                padding = { left = 1, right = 1 },
            })

            -- 3. Keep your existing encoding component on the right
            table.insert(opts.sections.lualine_x, "encoding")
        end,
    },
}
